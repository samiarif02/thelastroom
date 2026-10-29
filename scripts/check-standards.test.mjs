import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { ciJob, CHECKS, fencedBlocks, npmRuns, runChecks } from './check-standards.mjs'

const REPO = fileURLToPath(new URL('..', import.meta.url))

test('npmRuns reads gate invocations in order', () => {
	assert.deepEqual(npmRuns('npm run analyze\nfoo && npm run --silent check:env # x\nnpm test'), ['analyze', 'check:env'])
})

test('fencedBlocks ignores prose, so a gate mentioned in a sentence does not count', () => {
	const md = 'Run `npm run analyze` in prose.\n\n```bash\nnpm run test\n```\n'
	assert.deepEqual(npmRuns(fencedBlocks(md)), ['test'])
})

test('ciJob returns one job and stops at the next', () => {
	const yaml = 'jobs:\n  commits:\n    steps:\n      - run: npm run a\n  check:\n    steps:\n      - run: npm run b\n  other:\n      - run: npm run c\n'
	assert.deepEqual(npmRuns(ciJob(yaml, 'check')), ['b'])
})

test('every check has a unique id', () => {
	const ids = CHECKS.map((c) => c.id)
	assert.equal(new Set(ids).size, ids.length)
})

test('an empty directory fails every check rather than passing by finding nothing', () => {
	const dir = mkdtempSync(join(tmpdir(), 'standards-'))
	try {
		const results = runChecks(dir)
		const passed = results.filter((r) => r.ok).map((r) => r.id)
		assert.deepEqual(passed, [], `passed on an empty dir: ${passed.join(', ')}`)
	} finally {
		rmSync(dir, { recursive: true, force: true })
	}
})

test("this repo's file-level standards are met (git-index checks are CI's job)", () => {
	const gitOnly = new Set([
		'commit-msg-hook',
		'secrets-scan',
		'pre-push-hook',
		'session-logs-tracked',
		'no-machine-local-state-tracked'
	])
	const failing = runChecks(REPO).filter((r) => !r.ok && !gitOnly.has(r.id))
	assert.deepEqual(failing, [])
})
