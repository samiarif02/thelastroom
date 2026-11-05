// Security audit 2026-11-05: the release workflow holds `contents: write` and builds the APK,
// so every action it runs is pinned to a commit, not a tag that can be moved.
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import assert from 'node:assert/strict'

test('every action in release-apk.yml is pinned to a full commit SHA', () => {
	const workflow = readFileSync(new URL('../.github/workflows/release-apk.yml', import.meta.url), 'utf8')
	const uses = [...workflow.matchAll(/^\s*-?\s*uses:\s*(\S+)/gm)].map((m) => m[1])
	assert.ok(uses.length > 0, 'the workflow uses actions')
	for (const action of uses) {
		assert.match(action, /^[\w.-]+\/[\w.-]+@[0-9a-f]{40}$/, `${action} is pinned to a SHA`)
	}
})
