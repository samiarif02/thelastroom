// Renders every mockup HTML in a direction folder to JPEG with headless Chrome.
// Usage: PUPPETEER_CORE=<path to puppeteer-core> CHROME=<chrome binary> node render.mjs <dir> [file...]
// Phone screens render at 390 x 844 (2x); a file named *-1440.html renders at 1440 wide (1x),
// with its height taken from <meta name="mockup-height">.
import { readdirSync, statSync } from 'node:fs'
import { join, resolve, basename } from 'node:path'
import { pathToFileURL } from 'node:url'

const { default: puppeteer } = await import(process.env.PUPPETEER_CORE)
const dir = resolve(process.argv[2])
const only = process.argv.slice(3)
const files = readdirSync(dir).filter((f) => f.endsWith('.html') && (only.length === 0 || only.includes(f)))
const browser = await puppeteer.launch({ executablePath: process.env.CHROME, headless: true, args: ['--no-sandbox'] })
for (const f of files) {
	const page = await browser.newPage()
	const wide = f.includes('-1440')
	await page.setViewport({ width: wide ? 1440 : 390, height: 844, deviceScaleFactor: wide ? 1 : 2 })
	await page.goto(pathToFileURL(join(dir, f)).href, { waitUntil: 'networkidle0' })
	await page.evaluate(() => document.fonts.ready)
	const h = await page.evaluate(() => Number(document.querySelector('meta[name="mockup-height"]')?.content || 844))
	await page.setViewport({ width: wide ? 1440 : 390, height: h, deviceScaleFactor: wide ? 1 : 2 })
	await new Promise((r) => setTimeout(r, 300))
	let q = 86
	let out
	for (;;) {
		out = join(dir, 'png', basename(f, '.html') + '.jpg')
		await page.screenshot({ path: out, type: 'jpeg', quality: q })
		const kb = statSync(out).size / 1024
		if (kb < 195 || q <= 50) { console.log(`${f} -> ${out} ${kb.toFixed(0)} KB q${q}`); break }
		q -= 6
	}
	await page.close()
}
await browser.close()
