#!/usr/bin/env node
// Runs every workspace package's Dart tests: `flutter test` for packages that depend on the
// Flutter SDK, `dart test` for pure-Dart ones (engine, content). The package list is read from
// the root pubspec.yaml's `workspace:` block, so a new package is tested without editing this
// file. A package with no test/ directory, or a workspace list that parses to nothing, fails:
// a test gate that can pass by running nothing is not a gate (docs/STANDARDS.md in 8x's
// template-web, "what nearly went wrong").
//
// Usage: node scripts/test-packages.mjs [package-dir ...]

import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

export function workspacePackages(rootPubspec) {
	const lines = rootPubspec.split('\n')
	const start = lines.findIndex((l) => /^workspace:\s*$/.test(l))
	if (start === -1) return []
	const packages = []
	for (const line of lines.slice(start + 1)) {
		const m = line.match(/^\s+-\s+(\S+)\s*$/)
		if (m) packages.push(m[1])
		else if (/^\S/.test(line)) break
	}
	return packages
}

export function usesFlutter(pubspec) {
	return /^\s+flutter:\s*\n\s+sdk:\s*flutter/m.test(pubspec)
}

function hasTests(dir) {
	const testDir = join(dir, 'test')
	if (!existsSync(testDir)) return false
	const walk = (d) =>
		readdirSync(d, { withFileTypes: true }).some((e) =>
			e.isDirectory() ? walk(join(d, e.name)) : e.name.endsWith('_test.dart')
		)
	return walk(testDir)
}

function main() {
	const root = process.cwd()
	const args = process.argv.slice(2)
	const packages = args.length ? args : workspacePackages(readFileSync(join(root, 'pubspec.yaml'), 'utf8'))
	if (packages.length === 0) {
		console.error('test-packages: found no workspace packages in pubspec.yaml; refusing to pass')
		process.exit(1)
	}
	let failed = []
	for (const pkg of packages) {
		const dir = join(root, pkg)
		if (!hasTests(dir)) {
			console.error(`✗ ${pkg}: no *_test.dart under test/`)
			failed.push(pkg)
			continue
		}
		const tool = usesFlutter(readFileSync(join(dir, 'pubspec.yaml'), 'utf8')) ? 'flutter' : 'dart'
		console.log(`\n▶ ${pkg} (${tool} test)`)
		const res = spawnSync(tool, ['test'], { cwd: dir, stdio: 'inherit' })
		if (res.status !== 0) failed.push(pkg)
	}
	if (failed.length) {
		console.error(`\ntest-packages: failed: ${failed.join(', ')}`)
		process.exit(1)
	}
	console.log(`\ntest-packages: all ${packages.length} packages passed`)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
