#!/usr/bin/env node
// The event registry gate (8x STANDARDS: "events are registered before the feature", ported).
//
// In Dart the compiler already does half the job: Analytics.track() only accepts an
// AnalyticsEvent, so an unregistered event can't compile. This check covers the rest:
//   1. the enum and docs/EVENTS.md list exactly the same wire names (docs can't drift);
//   2. nothing outside lib/core/analytics/ fires an event by string or talks to the analytics
//      SDK directly (`.capture(`, `Posthog(`), and no wire name appears as a string literal
//      elsewhere (a sign someone is building names by hand);
//   3. registered-but-never-fired events are listed as warnings (expected before features).
//
// Usage: node scripts/check-events.mjs [--root <dir>]

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { pathToFileURL } from 'node:url'

export const REGISTRY = 'apps/mobile/lib/core/analytics/analytics_event.dart'
export const ANALYTICS_DIR = 'apps/mobile/lib/core/analytics/'
export const APP_LIB = 'apps/mobile/lib'
export const EVENTS_DOC = 'docs/EVENTS.md'

export function registryEvents(source) {
	return [...source.matchAll(/^\s*(\w+)\('([a-z0-9_]+)'\)[,;]/gm)].map((m) => ({ dartName: m[1], wireName: m[2] }))
}

export function documentedEvents(markdown) {
	// The first cell of each table row, written as `event_name`.
	return [...markdown.matchAll(/^\|\s*`([a-z0-9_]+)`\s*\|/gm)].map((m) => m[1])
}

const FORBIDDEN = [
	{ re: /\.track\(\s*['"]/, why: 'fires an event by string; pass an AnalyticsEvent' },
	{ re: /\.capture\(/, why: 'calls the analytics SDK directly; use Analytics.track' },
	{ re: /\bPosthog\(\)/, why: 'uses the PostHog SDK outside core/analytics' }
]

function walk(dir) {
	if (!existsSync(dir)) return []
	return readdirSync(dir).flatMap((name) => {
		const p = join(dir, name)
		return statSync(p).isDirectory() ? walk(p) : p.endsWith('.dart') ? [p] : []
	})
}

export function checkEvents(root) {
	const errors = []
	const warnings = []
	if (!existsSync(join(root, REGISTRY))) return { errors: [`${REGISTRY} is missing`], warnings }
	const events = registryEvents(readFileSync(join(root, REGISTRY), 'utf8'))
	if (events.length === 0) return { errors: [`${REGISTRY}: found no events in the enum`], warnings }
	const wire = new Set(events.map((e) => e.wireName))

	if (!existsSync(join(root, EVENTS_DOC))) {
		errors.push(`${EVENTS_DOC} is missing`)
	} else {
		const documented = new Set(documentedEvents(readFileSync(join(root, EVENTS_DOC), 'utf8')))
		if (documented.size === 0) errors.push(`${EVENTS_DOC}: found no \`event_name\` table rows`)
		for (const w of wire) if (!documented.has(w)) errors.push(`${w} is in the enum but not in ${EVENTS_DOC}`)
		for (const d of documented) if (!wire.has(d)) errors.push(`${d} is in ${EVENTS_DOC} but not in the enum`)
	}

	const files = walk(join(root, APP_LIB))
	if (files.length === 0) errors.push(`${APP_LIB}: found no Dart files to scan`)
	const fired = new Set()
	for (const file of files) {
		const rel = relative(root, file)
		if (rel.startsWith(ANALYTICS_DIR)) continue
		const src = readFileSync(file, 'utf8')
		src.split('\n').forEach((line, i) => {
			for (const { re, why } of FORBIDDEN) if (re.test(line)) errors.push(`${rel}:${i + 1} ${why}`)
			for (const w of wire) if (line.includes(`'${w}'`) || line.includes(`"${w}"`)) errors.push(`${rel}:${i + 1} writes the event name '${w}' as a string`)
		})
		for (const m of src.matchAll(/AnalyticsEvent\.(\w+)/g)) fired.add(m[1])
	}
	const unfired = events.filter((e) => !fired.has(e.dartName)).map((e) => e.wireName)
	if (unfired.length) warnings.push(`registered but not yet fired (${unfired.length}): ${unfired.join(', ')}`)
	return { errors, warnings, count: events.length }
}

function main() {
	const i = process.argv.indexOf('--root')
	const root = i === -1 ? process.cwd() : process.argv[i + 1]
	const { errors, warnings, count = 0 } = checkEvents(root)
	for (const w of warnings) console.warn(`  ~ ${w}`)
	if (errors.length) {
		for (const e of errors) console.error(`  ✗ ${e}`)
		console.error(`check:events: ${errors.length} problem(s)`)
		process.exit(1)
	}
	console.log(`check:events: ok (${count} events registered and documented)`)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
