import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { usesFlutter, workspacePackages } from './test-packages.mjs'

test('reads the workspace list and stops at the next top-level key', () => {
	const pubspec = 'name: x\nworkspace:\n  - apps/mobile\n  - packages/engine\n\ndev_dependencies:\n  - nope\n'
	assert.deepEqual(workspacePackages(pubspec), ['apps/mobile', 'packages/engine'])
})

test('finds no packages when there is no workspace block', () => {
	assert.deepEqual(workspacePackages('name: x\n'), [])
})

test("this repo's workspace lists the app and all three packages", () => {
	const pkgs = workspacePackages(readFileSync(new URL('../pubspec.yaml', import.meta.url), 'utf8'))
	for (const p of ['apps/mobile', 'packages/brand', 'packages/content', 'packages/engine']) {
		assert.ok(pkgs.includes(p), p)
	}
})

test('tells Flutter packages from pure-Dart ones', () => {
	assert.equal(usesFlutter('dependencies:\n  flutter:\n    sdk: flutter\n'), true)
	assert.equal(usesFlutter('dependencies:\n  engine:\n'), false)
})
