#!/usr/bin/env node
// The standards checklist, and the check that proves it. Ported from 8x's
// template-web scripts/check-standards.mjs (docs/STANDARDS.md there): the same
// engineering discipline, re-expressed for a Flutter + Supabase monorepo. Where a
// check keeps the template's id it means the same thing; Flutter-only checks have
// new ids. AGENTS.md "Where this repo differs from 8x's templates" explains each mapping.
//
// Deterministic: no network, no model, same answer on every run, exit code CI gates on.
// Every check that scans text asserts it found something before judging what it found.
//
// Usage:
//   node scripts/check-standards.mjs                 # this repo
//   node scripts/check-standards.mjs --root <dir>    # audit another checkout
//   node scripts/check-standards.mjs --json          # machine-readable

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { join, relative } from 'node:path'
import { pathToFileURL } from 'node:url'

// ---------------------------------------------------------------------------
// Configuration: what this repo holds itself to.
// ---------------------------------------------------------------------------

export const CORE_RULES = [
	// 8x's stack-agnostic core set
	'code-quality',
	'commits',
	'deployment',
	'logging',
	'migrations',
	'pull-requests',
	// the rest this repo requires
	'secrets',
	'analytics',
	'state-management',
	'components',
	'error-handling'
]

export const REQUIRED_SCRIPTS = {
	analyze: /flutter analyze .*--fatal-infos|dart analyze .*--fatal-infos/,
	'format:check': /dart format .*--set-exit-if-changed/,
	test: /./,
	'check:secrets': /check-secrets\.mjs/,
	'check:standards': /check-standards\.mjs/,
	'check:events': /check-events\.mjs/,
	'check:env': /check-env\.mjs/,
	'check:rls': /check-rls\.mjs/,
	'test:db': /supabase test db/
}

// Gates CI must run on every PR (format runs as format:check).
export const CI_GATES = [...Object.keys(REQUIRED_SCRIPTS), 'build:web']

// The CI jobs whose `npm run` gates local-review runs too, in this order: the gates job, then
// the database job (migrations replayed + pgTAP RLS tests, which needs Docker).
export const CI_MIRRORED_JOBS = ['check', 'db']

export const HANDOFF_SECTIONS = [
	'Current goal',
	'Branch',
	'Done',
	'In progress',
	'Next steps',
	'Open decisions',
	'Gotchas'
]

// Paths that must be ignored (probed at the root AND nested) and never tracked.
export const MACHINE_LOCAL_PROBES = [
	'.env',
	'.env.local',
	'.env.production',
	'apps/mobile/.env',
	'apps/mobile/env/dev.json',
	'apps/mobile/env/prod.json',
	'.DS_Store',
	'apps/mobile/.DS_Store',
	'node_modules/x',
	'.dart_tool/x',
	'apps/mobile/.dart_tool/x',
	'build/x',
	'apps/mobile/build/x',
	'supabase/.temp/x',
	'apps/mobile/android/local.properties',
	'apps/mobile/android/key.properties',
	'release.jks',
	'.claude/settings.local.json'
]
const TRACKED_ALLOWED = /(^|\/)(\.env\.example|[^/]+\.example\.json)$/
const MACHINE_LOCAL_TRACKED =
	/(^|\/)(\.env(\.[^/]*)?|\.DS_Store|node_modules\/|\.dart_tool\/|build\/|local\.properties|key\.properties|[^/]+\.jks|[^/]+\.keystore|settings\.local\.json)$|(^|\/)env\/[^/]+\.json$|(^|\/)(node_modules|\.dart_tool|build)\//

// Where widgets live: no raw colours allowed outside packages/brand.
const COLOUR_SCAN_DIRS = ['apps/mobile/lib', 'packages/engine/lib', 'packages/content/lib']
const RAW_COLOUR = /\bColor\(\s*0x|\bColor\.from(ARGB|RGBO)\(|\bColors\.\w+/

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function ctx(root) {
	const p = (rel) => join(root, rel)
	const exists = (rel) => existsSync(p(rel))
	const read = (rel) => (exists(rel) ? readFileSync(p(rel), 'utf8') : '')
	const git = (...args) => spawnSync('git', ['-C', root, ...args], { encoding: 'utf8' })
	const isGit = git('rev-parse', '--is-inside-work-tree').stdout.trim() === 'true'
	const indexMode = (rel) => {
		const out = git('ls-files', '-s', '--', rel).stdout.trim()
		return out ? out.split(/\s+/)[0] : null
	}
	const executable = (rel) => exists(rel) && (statSync(p(rel)).mode & 0o111) !== 0
	const pkg = (() => {
		try {
			return JSON.parse(read('package.json'))
		} catch {
			return null
		}
	})()
	const walk = (rel, ext) => {
		if (!exists(rel)) return []
		return readdirSync(p(rel)).flatMap((name) => {
			const child = `${rel}/${name}`
			return statSync(p(child)).isDirectory() ? walk(child, ext) : child.endsWith(ext) ? [child] : []
		})
	}
	return { root, p, exists, read, git, isGit, indexMode, executable, pkg, walk }
}

// The `npm run <x>` invocations in a block of text, in order.
export function npmRuns(text) {
	return [...text.matchAll(/\bnpm run (?:--silent )?([a-z0-9:_-]+)/g)].map((m) => m[1])
}

// Only the fenced command blocks of a markdown file: a mention in prose does not count.
export function fencedBlocks(markdown) {
	return [...markdown.matchAll(/```(?:bash|sh|shell)?\n([\s\S]*?)```/g)].map((m) => m[1]).join('\n')
}

// The steps of one CI job, by job id (a minimal reader for our own ci.yml layout).
export function ciJob(yaml, jobId) {
	const lines = yaml.split('\n')
	const start = lines.findIndex((l) => l === `  ${jobId}:`)
	if (start === -1) return ''
	const end = lines.findIndex((l, i) => i > start && /^  [a-z0-9_-]+:\s*$/i.test(l))
	return lines.slice(start, end === -1 ? undefined : end).join('\n')
}

function hookCheck(c, rel, mustCall) {
	const f = []
	if (!c.exists(rel)) return [`${rel} is missing`]
	if (!c.executable(rel)) f.push(`${rel} is not executable (chmod +x)`)
	if (c.isGit) {
		const mode = c.indexMode(rel)
		if (mode === null) f.push(`${rel} is not in the git index (git add it)`)
		else if (mode !== '100755') f.push(`${rel} is ${mode} in git, not 100755 (git update-index --chmod=+x ${rel})`)
	} else f.push(`not a git repository, so ${rel}'s index mode can't be checked`)
	if (!c.read(rel).includes(mustCall)) f.push(`${rel} doesn't call ${mustCall}`)
	return f
}

// ---------------------------------------------------------------------------
// The checks. Each returns a list of failures; empty means met.
// ---------------------------------------------------------------------------

export const CHECKS = [
	// --- Agent instructions
	{
		id: 'agents-md',
		run: (c) =>
			!c.exists('AGENTS.md')
				? ['AGENTS.md is missing']
				: /^## Engineering rules\s*$/m.test(c.read('AGENTS.md'))
					? []
					: ['AGENTS.md has no "## Engineering rules" section']
	},
	{
		id: 'agents-md-links-resolve',
		run: (c) => {
			const links = [...c.read('AGENTS.md').matchAll(/\((docs\/rules\/[a-z0-9-]+\.md)\)/g)].map((m) => m[1])
			if (links.length === 0) return ['AGENTS.md links to no docs/rules/*.md file']
			return links.filter((l) => !c.exists(l)).map((l) => `AGENTS.md links to ${l}, which doesn't exist`)
		}
	},
	{
		id: 'rules-all-linked',
		run: (c) => {
			if (!c.exists('docs/rules')) return ['docs/rules/ is missing']
			const agents = c.read('AGENTS.md')
			return readdirSync(c.p('docs/rules'))
				.filter((n) => n.endsWith('.md'))
				.filter((n) => !agents.includes(`(docs/rules/${n})`))
				.map((n) => `docs/rules/${n} is not linked from AGENTS.md`)
		}
	},
	{
		id: 'rules-core-set',
		run: (c) => CORE_RULES.filter((r) => !c.exists(`docs/rules/${r}.md`)).map((r) => `docs/rules/${r}.md is missing`)
	},
	{
		id: 'per-tool-entry-points',
		run: (c) => {
			const f = []
			if (!/^@AGENTS\.md\s*$/m.test(c.read('CLAUDE.md'))) f.push('CLAUDE.md has no "@AGENTS.md" line')
			for (const extra of ['GEMINI.md', 'QWEN.md', '.cursor/rules/project.mdc']) {
				if (c.exists(extra) && !c.read(extra).includes('@AGENTS.md')) f.push(`${extra} doesn't import @AGENTS.md`)
			}
			return f
		}
	},
	{ id: 'readme', run: (c) => (c.exists('README.md') ? [] : ['README.md is missing']) },

	// --- Commit discipline
	{
		id: 'commit-msg-hook',
		run: (c) => hookCheck(c, '.githooks/commit-msg', 'scripts/check-commit-message.mjs')
	},
	{
		id: 'hooks-path-installed',
		run: (c) =>
			/git config core\.hooksPath \.githooks/.test(c.pkg?.scripts?.prepare ?? '')
				? []
				: ["package.json's prepare script doesn't run `git config core.hooksPath .githooks`"]
	},
	{
		id: 'ci-commits-job',
		run: (c) =>
			/check-commit-message\.mjs --range/.test(c.read('.github/workflows/ci.yml'))
				? []
				: ["CI doesn't run scripts/check-commit-message.mjs --range over the PR's commits"]
	},
	{
		id: 'secrets-scan',
		run: (c) => {
			const f = []
			if (!c.exists('scripts/check-secrets.mjs')) f.push('scripts/check-secrets.mjs is missing')
			f.push(...hookCheck(c, '.githooks/pre-commit', 'scripts/check-secrets.mjs'))
			if (!REQUIRED_SCRIPTS['check:secrets'].test(c.pkg?.scripts?.['check:secrets'] ?? ''))
				f.push('the check:secrets script does not run scripts/check-secrets.mjs')
			if (!npmRuns(c.read('.github/workflows/ci.yml')).includes('check:secrets')) f.push("CI doesn't run check:secrets")
			return f
		}
	},
	{
		id: 'pre-push-hook',
		run: (c) => hookCheck(c, '.githooks/pre-push', 'npm run')
	},

	// --- Gates
	{
		id: 'package-scripts',
		run: (c) => {
			if (!c.pkg) return ["package.json is missing or isn't valid JSON"]
			return Object.entries(REQUIRED_SCRIPTS)
				.filter(([name, re]) => !re.test(c.pkg.scripts?.[name] ?? ''))
				.map(([name, re]) => `package.json script "${name}" is missing or doesn't match ${re}`)
		}
	},
	{
		id: 'ci-gates-every-pr',
		run: (c) => {
			const ci = c.read('.github/workflows/ci.yml')
			if (!ci) return ['.github/workflows/ci.yml is missing']
			const f = []
			if (!/^\s*pull_request:/m.test(ci)) f.push("CI doesn't trigger on pull_request")
			const runs = npmRuns(ci)
			for (const g of CI_GATES) if (!runs.includes(g)) f.push(`CI doesn't run \`npm run ${g}\``)
			return f
		}
	},
	{
		id: 'local-review-mirrors-ci',
		run: (c) => {
			const skill = '.claude/skills/local-review/SKILL.md'
			if (!c.exists(skill)) return [`${skill} is missing`]
			const ci = c.read('.github/workflows/ci.yml')
			const ciRuns = CI_MIRRORED_JOBS.flatMap((job) => npmRuns(ciJob(ci, job)))
			const reviewRuns = npmRuns(fencedBlocks(c.read(skill)))
			if (ciRuns.length === 0) return ["found no `npm run` gates in CI's check job"]
			if (reviewRuns.join(' ') !== ciRuns.join(' '))
				return [`local-review runs [${reviewRuns.join(', ')}] but CI's ${CI_MIRRORED_JOBS.join(' + ')} jobs run [${ciRuns.join(', ')}]; same gates, same order`]
			return []
		}
	},
	{
		id: 'dart-analysis-strict',
		run: (c) => {
			const a = c.read('analysis_options.yaml')
			if (!a) return ['analysis_options.yaml is missing']
			const f = []
			for (const flag of ['strict-casts', 'strict-inference', 'strict-raw-types'])
				if (!new RegExp(`^\\s+${flag}:\\s*true`, 'm').test(a)) f.push(`analysis_options.yaml doesn't set ${flag}: true`)
			for (const lint of ['avoid_print', 'avoid_dynamic_calls'])
				if (!new RegExp(`^\\s+-\\s+${lint}\\s*$`, 'm').test(a)) f.push(`analysis_options.yaml doesn't enable ${lint}`)
			// A package-level analysis_options.yaml would replace the root one for that package.
			for (const dir of ['apps', 'packages']) {
				if (!c.exists(dir)) continue
				for (const pkg of readdirSync(c.p(dir))) {
					const own = `${dir}/${pkg}/analysis_options.yaml`
					if (c.exists(own) && !/include:\s*\.\.\/\.\.\/analysis_options\.yaml/.test(c.read(own)))
						f.push(`${own} overrides the root strict config without including it`)
				}
			}
			return f
		}
	},
	{
		id: 'flutter-version-pinned',
		run: (c) => {
			const readme = c.read('README.md').match(/Flutter \*\*(\d+\.\d+\.\d+)\*\*/)
			const ci = c.read('.github/workflows/ci.yml').match(/flutter-version:\s*['"]?(\d+\.\d+\.\d+)/)
			if (!readme) return ['README.md doesn\'t pin a Flutter version as "Flutter **x.y.z**"']
			if (!ci) return ["CI doesn't pin flutter-version: x.y.z"]
			return readme[1] === ci[1] ? [] : [`README pins Flutter ${readme[1]} but CI pins ${ci[1]}`]
		}
	},

	// --- Environment
	{
		id: 'env-schema',
		run: (c) => {
			const f = []
			if (!/String\.fromEnvironment/.test(c.read('apps/mobile/lib/core/env/env.dart')))
				f.push('apps/mobile/lib/core/env/env.dart is missing or reads no defines')
			for (const ex of ['apps/mobile/env/dev.example.json', '.env.example']) if (!c.exists(ex)) f.push(`${ex} is missing`)
			if (!c.exists('scripts/check-env.mjs')) f.push('scripts/check-env.mjs is missing')
			return f
		}
	},

	// --- Logging
	{
		id: 'structured-logger',
		run: (c) => {
			const f = []
			for (const file of ['apps/mobile/lib/core/logging/log.dart', 'apps/mobile/lib/core/logging/redact.dart'])
				if (!c.exists(file)) f.push(`${file} is missing`)
			if (!/test\(/.test(c.read('apps/mobile/test/core/log_test.dart'))) f.push('apps/mobile/test/core/log_test.dart is missing or empty')
			const libs = [...c.walk('apps/mobile/lib', '.dart'), ...c.walk('packages', '.dart').filter((p) => p.includes('/lib/'))]
			if (libs.length === 0) f.push('found no Dart library files to scan for print()')
			for (const file of libs) {
				c.read(file).split('\n').forEach((line, i) => {
					if (/(^|[^.\w])(print|debugPrint)\(/.test(line) && !line.trim().startsWith('//'))
						f.push(`${file}:${i + 1} prints; use the log wrapper (docs/rules/logging.md)`)
				})
			}
			return f
		}
	},

	// --- Design
	{
		id: 'brand-tokens-only',
		run: (c) => {
			const files = COLOUR_SCAN_DIRS.flatMap((d) => c.walk(d, '.dart'))
			if (files.length === 0) return ['found no Dart files to scan for raw colours']
			const f = []
			for (const file of files) {
				c.read(file).split('\n').forEach((line, i) => {
					if (RAW_COLOUR.test(line) && !line.trim().startsWith('//'))
						f.push(`${file}:${i + 1} writes a raw colour; use a packages/brand token`)
				})
			}
			return f
		}
	},
	{
		id: 'engine-pure-dart',
		run: (c) => {
			const pubspec = c.read('packages/engine/pubspec.yaml')
			if (!pubspec) return ['packages/engine/pubspec.yaml is missing']
			const f = []
			if (/sdk:\s*flutter/.test(pubspec)) f.push('packages/engine depends on Flutter; it must stay pure Dart')
			const files = c.walk('packages/engine/lib', '.dart')
			if (files.length === 0) f.push('found no engine source to scan')
			for (const file of files) {
				const src = c.read(file)
				if (/import 'package:flutter/.test(src)) f.push(`${file} imports Flutter`)
				if (/import 'dart:(io|html|ui)'/.test(src)) f.push(`${file} imports a platform library`)
				if (/DateTime\.now\(|Random\(\)/.test(src)) f.push(`${file} reads the clock or an unseeded Random; pass them in`)
			}
			return f
		}
	},

	// --- Repository hygiene
	{
		id: 'machine-local-state-ignored',
		run: (c) => {
			if (!c.isGit) return ['not a git repository']
			const res = c.git('check-ignore', '--no-index', ...MACHINE_LOCAL_PROBES)
			const ignored = new Set(res.stdout.split('\n').filter(Boolean))
			return MACHINE_LOCAL_PROBES.filter((p) => !ignored.has(p)).map((p) => `.gitignore doesn't ignore ${p}`)
		}
	},
	{
		id: 'no-machine-local-state-tracked',
		run: (c) => {
			if (!c.isGit) return ['not a git repository']
			return c
				.git('ls-files')
				.stdout.split('\n')
				.filter(Boolean)
				.filter((f) => MACHINE_LOCAL_TRACKED.test(f) && !TRACKED_ALLOWED.test(f))
				.map((f) => `${f} is machine-local state and is tracked (git rm --cached ${f})`)
		}
	},
	{
		id: 'session-logs-tracked',
		run: (c) => {
			if (!c.exists('.claude-logs')) return ['.claude-logs/ is missing']
			if (!c.isGit) return ['not a git repository']
			const f = []
			if (c.git('check-ignore', '-q', '--no-index', '.claude-logs/x.md').status === 0) f.push('.claude-logs/ is gitignored; it must be committed')
			if (!c.git('ls-files', '--', '.claude-logs').stdout.trim()) f.push('nothing in .claude-logs/ is tracked')
			return f
		}
	},
	{
		id: 'session-log-hooks',
		run: (c) => {
			const f = []
			if (!c.executable('.claude/hooks/extract-log.py')) f.push('.claude/hooks/extract-log.py is missing or not executable')
			let settings
			try {
				settings = JSON.parse(c.read('.claude/settings.json'))
			} catch {
				return [...f, '.claude/settings.json is missing or invalid']
			}
			for (const event of ['UserPromptSubmit', 'Stop', 'SubagentStop']) {
				if (!JSON.stringify(settings.hooks?.[event] ?? []).includes('extract-log.py'))
					f.push(`.claude/settings.json has no ${event} hook running extract-log.py`)
			}
			return f
		}
	},
	{
		id: 'shared-brain',
		run: (c) => {
			const f = []
			const handoff = c.read('docs/HANDOFF.md')
			if (!handoff) f.push('docs/HANDOFF.md is missing')
			for (const s of HANDOFF_SECTIONS)
				if (handoff && !new RegExp(`^## ${s}`, 'm').test(handoff)) f.push(`docs/HANDOFF.md has no "## ${s}" section`)
			const index = c.read('docs/memory/MEMORY.md')
			if (!index) return [...f, 'docs/memory/MEMORY.md is missing']
			const links = [...index.matchAll(/\]\(([^)]+\.md)\)/g)].map((m) => m[1])
			if (links.length === 0) f.push('docs/memory/MEMORY.md links to no memory files')
			for (const l of links) if (!c.exists(`docs/memory/${l}`)) f.push(`docs/memory/MEMORY.md links to ${l}, which doesn't exist`)
			for (const n of readdirSync(c.p('docs/memory')).filter((n) => n.endsWith('.md') && n !== 'MEMORY.md'))
				if (!links.includes(n)) f.push(`docs/memory/${n} is not indexed in MEMORY.md`)
			return f
		}
	}
]

export function runChecks(root) {
	const c = ctx(root)
	return CHECKS.map(({ id, run }) => {
		let failures
		try {
			failures = run(c)
		} catch (e) {
			failures = [`check crashed: ${e.message}`]
		}
		return { id, ok: failures.length === 0, failures }
	})
}

function main() {
	const args = process.argv.slice(2)
	const i = args.indexOf('--root')
	const root = i === -1 ? process.cwd() : args[i + 1]
	const results = runChecks(root)
	const failed = results.filter((r) => !r.ok)
	if (args.includes('--json')) {
		console.log(JSON.stringify({ root: relative(process.cwd(), root) || '.', results }, null, 2))
	} else {
		for (const r of results) {
			console.log(`${r.ok ? '✓' : '✗'} ${r.id}`)
			for (const f of r.failures) console.log(`    ${f}`)
		}
		console.log(`\ncheck:standards: ${results.length - failed.length}/${results.length} standards met`)
	}
	process.exit(failed.length ? 1 : 0)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
