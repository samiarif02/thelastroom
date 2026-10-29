#!/usr/bin/env node
// The RLS gate (8x STANDARDS check:rls, ported to Supabase SQL migrations).
//
// The app reads and writes its own rows directly, so RLS policies are the authorization layer
// (AGENTS.md, docs/rules/migrations.md rule 1). This is the static half of that rule: every
// `create table` in supabase/migrations/ has `enable row level security` and at least one
// `create policy` on the same table, in the same file, so no table is ever briefly open. The
// pgTAP tests in supabase/tests/ prove the policies actually do what they say.
//
// Also fails on any `disable row level security`. Comments are ignored.
//
// Usage: node scripts/check-rls.mjs [--root <dir>]

import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

export const MIGRATIONS_DIR = 'supabase/migrations'

const IDENT = String.raw`((?:"[^"]+"|[\w$]+)(?:\s*\.\s*(?:"[^"]+"|[\w$]+))?)`
const CREATE_TABLE = new RegExp(
	String.raw`\bcreate\s+(?:(?:global\s+|local\s+)?(temp|temporary)\s+|unlogged\s+)?table\s+(?:if\s+not\s+exists\s+)?${IDENT}`,
	'gi'
)
const ENABLE_RLS = new RegExp(
	String.raw`\balter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?${IDENT}\s+enable\s+row\s+level\s+security`,
	'gi'
)
const CREATE_POLICY = new RegExp(String.raw`\bcreate\s+policy\s+(?:"[^"]*"|\w+)\s+on\s+${IDENT}`, 'gi')
const DISABLE_RLS = /\bdisable\s+row\s+level\s+security\b/i

export function stripComments(sql) {
	return sql.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/--[^\n]*/g, '')
}

// `profiles`, `public.profiles` and `"public"."profiles"` are the same table.
export function canonical(name) {
	const parts = name.split('.').map((p) => {
		const t = p.trim()
		return t.startsWith('"') ? t.slice(1, -1) : t.toLowerCase()
	})
	return parts.length === 1 ? `public.${parts[0]}` : parts.join('.')
}

export function checkMigration(file, sql) {
	const body = stripComments(sql)
	const names = (re) => new Set([...body.matchAll(re)].map((m) => canonical(m[m.length - 1])))
	const tables = [...body.matchAll(CREATE_TABLE)].filter((m) => !m[1]).map((m) => canonical(m[2]))
	const rls = names(ENABLE_RLS)
	const policies = names(CREATE_POLICY)
	const errors = []
	for (const t of tables) {
		if (!rls.has(t)) errors.push(`${file}: creates ${t} without \`alter table ${t} enable row level security\``)
		if (!policies.has(t)) errors.push(`${file}: creates ${t} without a \`create policy ... on ${t}\``)
	}
	if (DISABLE_RLS.test(body)) errors.push(`${file}: disables row level security`)
	return { tables, errors }
}

export function checkRls(root) {
	const dir = join(root, MIGRATIONS_DIR)
	if (!existsSync(dir)) return { errors: [`${MIGRATIONS_DIR} is missing`], tables: [] }
	const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort()
	if (files.length === 0) return { errors: [`${MIGRATIONS_DIR}: found no .sql migrations`], tables: [] }
	const errors = []
	const tables = []
	for (const f of files) {
		const r = checkMigration(`${MIGRATIONS_DIR}/${f}`, readFileSync(join(dir, f), 'utf8'))
		errors.push(...r.errors)
		tables.push(...r.tables)
	}
	if (tables.length === 0) errors.push(`${MIGRATIONS_DIR}: found no \`create table\` to check`)
	return { errors, tables, files: files.length }
}

function main() {
	const i = process.argv.indexOf('--root')
	const root = i === -1 ? process.cwd() : process.argv[i + 1]
	const { errors, tables, files = 0 } = checkRls(root)
	if (errors.length) {
		for (const e of errors) console.error(`  ✗ ${e}`)
		console.error(`check:rls: ${errors.length} problem(s)`)
		process.exit(1)
	}
	console.log(`check:rls: ok (${tables.length} tables in ${files} migrations, each with RLS and a policy)`)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
