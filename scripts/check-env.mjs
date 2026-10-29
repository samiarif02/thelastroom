#!/usr/bin/env node
// Keeps the env schema, its documentation and the code in step (8x STANDARDS `env-schema`,
// ported to Flutter). Two sides:
//
// App (public config, compiled in with --dart-define-from-file):
//   - apps/mobile/lib/core/env/env.dart is the ONE file that reads String.fromEnvironment;
//   - the keys it reads == the keys in apps/mobile/env/dev.example.json, both ways;
//   - every other env/*.example.json declares the same keys.
// Server (Edge Function secrets):
//   - every Deno.env.get('X') under supabase/functions/ is documented in .env.example;
//   - a documented key nothing reads yet is a warning (the coach function lands later).
//
// Every scan asserts it found something: a check that passes by matching nothing is not a check.
//
// Usage: node scripts/check-env.mjs [--root <dir>]

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { pathToFileURL } from 'node:url'

export const ENV_DART = 'apps/mobile/lib/core/env/env.dart'
export const APP_LIB = 'apps/mobile/lib'
export const APP_ENV_DIR = 'apps/mobile/env'
export const DEV_EXAMPLE = 'apps/mobile/env/dev.example.json'
export const SERVER_EXAMPLE = '.env.example'
export const FUNCTIONS_DIR = 'supabase/functions'

// Supabase injects these into every Edge Function; they're never in .env.example.
const SUPABASE_PROVIDED = new Set([
	'SUPABASE_URL',
	'SUPABASE_ANON_KEY',
	'SUPABASE_SERVICE_ROLE_KEY',
	'SUPABASE_DB_URL'
])

export function dartDefineKeys(source) {
	return [...source.matchAll(/String\.fromEnvironment\(\s*'([A-Z0-9_]+)'/g)].map((m) => m[1])
}

export function dotenvKeys(source) {
	return source
		.split('\n')
		.map((l) => l.match(/^\s*(?:export\s+)?([A-Z0-9_]+)\s*=/))
		.filter(Boolean)
		.map((m) => m[1])
}

export function denoEnvReads(source) {
	return [...source.matchAll(/Deno\.env\.get\(\s*['"]([A-Z0-9_]+)['"]/g)].map((m) => m[1])
}

function walk(dir, ext) {
	if (!existsSync(dir)) return []
	return readdirSync(dir).flatMap((name) => {
		const p = join(dir, name)
		return statSync(p).isDirectory() ? walk(p, ext) : p.endsWith(ext) ? [p] : []
	})
}

const diff = (a, b) => [...a].filter((x) => !b.has(x))

export function checkEnv(root) {
	const errors = []
	const warnings = []
	const read = (p) => readFileSync(join(root, p), 'utf8')

	// --- App side
	if (!existsSync(join(root, ENV_DART))) {
		errors.push(`${ENV_DART} is missing`)
		return { errors, warnings }
	}
	const appKeys = new Set(dartDefineKeys(read(ENV_DART)))
	if (appKeys.size === 0) errors.push(`${ENV_DART}: found no String.fromEnvironment('KEY') reads`)

	const dartFiles = walk(join(root, APP_LIB), '.dart')
	if (dartFiles.length === 0) errors.push(`${APP_LIB}: found no Dart files to scan`)
	for (const file of dartFiles) {
		const rel = relative(root, file)
		if (rel === ENV_DART) continue
		const src = readFileSync(file, 'utf8')
		if (/\b(String|int|bool)\.fromEnvironment\(|Platform\.environment/.test(src)) {
			errors.push(`${rel} reads the environment; only ${ENV_DART} may`)
		}
	}

	if (!existsSync(join(root, DEV_EXAMPLE))) {
		errors.push(`${DEV_EXAMPLE} is missing`)
	} else {
		const exampleKeys = new Set(Object.keys(JSON.parse(read(DEV_EXAMPLE))))
		for (const k of diff(appKeys, exampleKeys)) errors.push(`${k} is read in env.dart but not documented in ${DEV_EXAMPLE}`)
		for (const k of diff(exampleKeys, appKeys)) errors.push(`${k} is in ${DEV_EXAMPLE} but env.dart never reads it`)
		for (const name of readdirSync(join(root, APP_ENV_DIR)).filter((n) => n.endsWith('.example.json'))) {
			const keys = new Set(Object.keys(JSON.parse(read(join(APP_ENV_DIR, name)))))
			const missing = diff(exampleKeys, keys)
			const extra = diff(keys, exampleKeys)
			if (missing.length || extra.length) {
				errors.push(`${APP_ENV_DIR}/${name} differs from dev.example.json (missing: ${missing.join(', ') || '-'}; extra: ${extra.join(', ') || '-'})`)
			}
		}
	}

	// --- Server side
	if (!existsSync(join(root, SERVER_EXAMPLE))) {
		errors.push(`${SERVER_EXAMPLE} is missing`)
	} else {
		const documented = new Set(dotenvKeys(read(SERVER_EXAMPLE)))
		if (documented.size === 0) errors.push(`${SERVER_EXAMPLE}: found no KEY= lines`)
		const reads = new Set()
		for (const file of walk(join(root, FUNCTIONS_DIR), '.ts')) {
			for (const k of denoEnvReads(readFileSync(file, 'utf8'))) {
				if (SUPABASE_PROVIDED.has(k)) continue
				reads.add(k)
				if (!documented.has(k)) errors.push(`${relative(root, file)} reads ${k}, which ${SERVER_EXAMPLE} doesn't document`)
			}
		}
		for (const k of diff(documented, reads)) warnings.push(`${k} is documented in ${SERVER_EXAMPLE} but no Edge Function reads it yet`)
	}

	return { errors, warnings, appKeys: [...appKeys] }
}

function main() {
	const i = process.argv.indexOf('--root')
	const root = i === -1 ? process.cwd() : process.argv[i + 1]
	const { errors, warnings, appKeys = [] } = checkEnv(root)
	for (const w of warnings) console.warn(`  ~ ${w}`)
	if (errors.length) {
		for (const e of errors) console.error(`  ✗ ${e}`)
		console.error(`check:env: ${errors.length} problem(s)`)
		process.exit(1)
	}
	console.log(`check:env: ok (${appKeys.length} app keys in step; ${warnings.length} warning(s))`)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
