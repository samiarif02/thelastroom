#!/usr/bin/env node
// A small load test for the hosted backend (issue 74, docs/scale-and-security.md). Zero
// dependencies (Node 22's fetch). It is never run by CI or by an agent: the owner runs it on
// purpose, against their own project, with the public anon key only.
//
//   SUPABASE_URL=https://<ref>.supabase.co SUPABASE_ANON_KEY=<anon key> \
//     node scripts/load-test.mjs --players 10 --rounds 20 [--score]
//
// What it does: signs in --players guests (anonymous sign-in, 30 an hour per IP on the hosted
// default, so keep it small), then each guest reads the leaderboard --rounds times, all guests at
// once. With --score, each guest also asks for one AI score (that spends one of their 30 a day
// and one Gemini call each). It prints the status codes and the p50 / p95 / max latency per call.
//
// What it never does: use a service key, write XP, or loop without end.

const MAX_PLAYERS = 25
const MAX_ROUNDS = 200

function arg(name, fallback) {
	const i = process.argv.indexOf(`--${name}`)
	if (i === -1) return fallback
	const n = Number(process.argv[i + 1])
	return Number.isFinite(n) && n > 0 ? n : fallback
}

const url = process.env.SUPABASE_URL ?? ''
const anonKey = process.env.SUPABASE_ANON_KEY ?? ''
const players = Math.min(arg('players', 5), MAX_PLAYERS)
const rounds = Math.min(arg('rounds', 10), MAX_ROUNDS)
const withScore = process.argv.includes('--score')

if (!url.startsWith('https://') || anonKey === '') {
	console.error('Set SUPABASE_URL (https://…) and SUPABASE_ANON_KEY (the public anon key).')
	process.exit(2)
}

const stats = new Map()

async function timed(name, call) {
	const started = performance.now()
	let status = 'network_error'
	try {
		const res = await call()
		status = String(res.status)
		await res.arrayBuffer()
	} catch {
		// counted as network_error
	}
	const entry = stats.get(name) ?? { ms: [], codes: {} }
	entry.ms.push(performance.now() - started)
	entry.codes[status] = (entry.codes[status] ?? 0) + 1
	stats.set(name, entry)
}

async function signIn() {
	const res = await fetch(`${url}/auth/v1/signup`, {
		method: 'POST',
		headers: { apikey: anonKey, 'content-type': 'application/json' },
		body: JSON.stringify({ data: {} })
	})
	if (!res.ok) {
		console.error(`anonymous sign-in answered ${res.status}`)
		return null
	}
	const json = await res.json()
	return typeof json.access_token === 'string' ? json.access_token : null
}

function headers(jwt) {
	return { apikey: anonKey, authorization: `Bearer ${jwt}`, 'content-type': 'application/json' }
}

// One built answer to Mission 1, as the app sends it (the lines are the content's).
const scoreBody = {
	mission_id: 'm01_the_opportunity',
	hiring_for: 'Product Associate (entry level)',
	interviewer_role: 'Recruiter',
	question: 'So, what made you apply for this role?',
	beats: [
		{ kind: 'open', line: 'I like finding out why people get stuck.', reason: 'It answers what she asked.', guessed: false },
		{ kind: 'evidence', line: 'I interviewed twelve students about it.', reason: null, guessed: false },
		{ kind: 'land', line: 'That is the work I want to do here.', reason: 'It ties back to the job.', guessed: false }
	],
	follow_up_question: 'What was your part in that?',
	reply: 'I ran the interviews myself and wrote up what I found.',
	attempt_id: null
}

async function player(jwt) {
	for (let i = 0; i < rounds; i++) {
		await timed('leaderboard', () =>
			fetch(`${url}/rest/v1/rpc/leaderboard`, {
				method: 'POST',
				headers: headers(jwt),
				body: JSON.stringify({ p_scope: i % 2 === 0 ? 'week' : 'all', p_limit: 50 })
			})
		)
	}
	if (withScore) {
		await timed('score', () =>
			fetch(`${url}/functions/v1/score`, { method: 'POST', headers: headers(jwt), body: JSON.stringify(scoreBody) })
		)
	}
}

function pct(sorted, p) {
	return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))]
}

const jwts = (await Promise.all(Array.from({ length: players }, signIn))).filter((j) => j !== null)
console.log(`${jwts.length} of ${players} guests signed in; ${rounds} board reads each${withScore ? ', one AI score each' : ''}`)
const started = performance.now()
await Promise.all(jwts.map(player))
const seconds = (performance.now() - started) / 1000

for (const [name, { ms, codes }] of stats) {
	const sorted = [...ms].sort((a, b) => a - b)
	const fmt = (n) => `${Math.round(n)} ms`
	console.log(
		`${name}: ${ms.length} calls, ${(ms.length / seconds).toFixed(1)}/s, codes ${JSON.stringify(codes)}, ` +
			`p50 ${fmt(pct(sorted, 50))}, p95 ${fmt(pct(sorted, 95))}, max ${fmt(sorted.at(-1))}`
	)
}
