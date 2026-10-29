import { test } from 'node:test'
import assert from 'node:assert/strict'
import { cpSync, mkdtempSync, rmSync, writeFileSync, mkdirSync, readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { checkEvents, documentedEvents, registryEvents, EVENTS_DOC, REGISTRY } from './check-events.mjs'

const REPO = fileURLToPath(new URL('..', import.meta.url))

function withCopy(fn) {
	const dir = mkdtempSync(join(tmpdir(), 'check-events-'))
	try {
		for (const p of ['apps/mobile/lib', EVENTS_DOC]) cpSync(join(REPO, p), join(dir, p), { recursive: true })
		return fn(dir)
	} finally {
		rmSync(dir, { recursive: true, force: true })
	}
}

const put = (dir, path, text) => {
	mkdirSync(dirname(join(dir, path)), { recursive: true })
	writeFileSync(join(dir, path), text)
}

test('parses the enum and the docs table', () => {
	assert.deepEqual(registryEvents("enum E {\n  aB('a_b'),\n  cD('c_d');\n}"), [
		{ dartName: 'aB', wireName: 'a_b' },
		{ dartName: 'cD', wireName: 'c_d' }
	])
	assert.deepEqual(documentedEvents('| Event | x |\n| --- | --- |\n| `a_b` | y |\n'), ['a_b'])
})

test("this repo's registry and docs agree", () => {
	assert.deepEqual(checkEvents(REPO).errors, [])
})

test('fails when an enum value is missing from EVENTS.md', () => {
	withCopy((dir) => {
		const src = readFileSync(join(dir, REGISTRY), 'utf8').replace(
			"waitlistJoined('waitlist_joined'),",
			"waitlistJoined('waitlist_joined'),\n  paywallViewed('paywall_viewed'),"
		)
		put(dir, REGISTRY, src)
		assert.ok(checkEvents(dir).errors.some((e) => e.includes('paywall_viewed')))
	})
})

test('fails on a string event name or a direct SDK call in feature code', () => {
	withCopy((dir) => {
		put(dir, 'apps/mobile/lib/features/x.dart', "void f(a) { a.track('mission_started'); a.capture('x'); }\n")
		const { errors } = checkEvents(dir)
		assert.ok(errors.some((e) => e.includes('by string')))
		assert.ok(errors.some((e) => e.includes('SDK directly')))
		assert.ok(errors.some((e) => e.includes("'mission_started' as a string")))
	})
})

test('a registered event nobody fires is a warning, not an error', () => {
	const { errors, warnings } = checkEvents(REPO)
	assert.deepEqual(errors, [])
	assert.ok(warnings.some((w) => w.includes('not yet fired')))
})
