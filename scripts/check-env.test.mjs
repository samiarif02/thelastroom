import { test } from 'node:test'
import assert from 'node:assert/strict'
import { cpSync, mkdtempSync, rmSync, writeFileSync, mkdirSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { checkEnv, dartDefineKeys, denoEnvReads, dotenvKeys, DEV_EXAMPLE, ENV_DART } from './check-env.mjs'

const REPO = fileURLToPath(new URL('..', import.meta.url))

function withCopy(fn) {
	const dir = mkdtempSync(join(tmpdir(), 'check-env-'))
	try {
		for (const p of ['apps/mobile/lib', 'apps/mobile/env', '.env.example']) {
			cpSync(join(REPO, p), join(dir, p), { recursive: true })
		}
		return fn(dir)
	} finally {
		rmSync(dir, { recursive: true, force: true })
	}
}

const put = (dir, path, text) => {
	mkdirSync(dirname(join(dir, path)), { recursive: true })
	writeFileSync(join(dir, path), text)
}

test('parsers find keys in each format', () => {
	assert.deepEqual(dartDefineKeys("x: String.fromEnvironment('A_B'),\ny: String.fromEnvironment(\n 'C')"), ['A_B', 'C'])
	assert.deepEqual(dotenvKeys('# c\nA=\nexport B=1\n  C = x\nlower=no'), ['A', 'B', 'C'])
	assert.deepEqual(denoEnvReads("Deno.env.get('X'); Deno.env.get(\"Y\")"), ['X', 'Y'])
})

test("this repo's env is in step", () => {
	const { errors } = checkEnv(REPO)
	assert.deepEqual(errors, [])
})

test('fails when env.dart reads a key the example file does not document', () => {
	withCopy((dir) => {
		put(dir, ENV_DART, "const a = String.fromEnvironment('NEW_KEY');\n")
		const { errors } = checkEnv(dir)
		assert.ok(errors.some((e) => e.includes('NEW_KEY')))
	})
})

test('fails when another file reads a define', () => {
	withCopy((dir) => {
		put(dir, 'apps/mobile/lib/rogue.dart', "const k = String.fromEnvironment('APP_ENV');\n")
		assert.ok(checkEnv(dir).errors.some((e) => e.includes('rogue.dart')))
	})
})

test('fails when an Edge Function reads an undocumented secret, not a Supabase-provided one', () => {
	withCopy((dir) => {
		put(dir, 'supabase/functions/coach/index.ts', "Deno.env.get('SUPABASE_URL'); Deno.env.get('OPENAI_KEY')\n")
		const { errors } = checkEnv(dir)
		assert.ok(errors.some((e) => e.includes('OPENAI_KEY')))
		assert.ok(!errors.some((e) => e.includes('SUPABASE_URL')))
	})
})

test('refuses to pass when it finds no keys at all', () => {
	withCopy((dir) => {
		put(dir, ENV_DART, '// nothing here\n')
		put(dir, DEV_EXAMPLE, '{}\n')
		assert.ok(checkEnv(dir).errors.some((e) => e.includes('found no')))
	})
})
