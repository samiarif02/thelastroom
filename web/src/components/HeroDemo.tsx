'use client'

import { Pause, Play } from '@phosphor-icons/react'
import { type ReactNode, useEffect, useRef, useState } from 'react'

import type { Expression } from '@/cast/people'
import { demo } from '@/content/site'

import { afterLoad } from './afterLoad'
import styles from './HeroDemo.module.css'

// The hero phone plays room 4 on a loop (w8's HeroPhone idea, restyled): Marcus's line types
// out, the cards rise in, line B is chosen, the "why" sheet rises with his nod, the debrief
// counts up, and room 4 lights up in the tower. The big Marcus in the arch reacts with the phone.
//
// The markup is the resting frame (line B chosen), which is what shows without JavaScript and,
// until the visitor presses play, under reduced motion. The loop pauses off screen, in a hidden
// tab and on the pause button (WCAG 2.2.2: anything moving for over five seconds can be stopped).

type Step = 'talk' | 'choose' | 'pick' | 'why' | 'score' | 'tower'

/** Each step and how long it holds, in ms. `talk` holds this long after the typing ends. */
const steps: readonly (readonly [Step, number])[] = [
	['talk', 700],
	['choose', 1500],
	['pick', 1400],
	['why', 2800],
	['score', 3200],
	['tower', 3400]
]

/** What the interviewer's face does at each step (direction.md's cast state machine). */
const faces: Readonly<Record<Step, Expression>> = {
	talk: 'talk',
	choose: 'listening',
	pick: 'listening',
	why: 'nod',
	score: 'smile',
	tower: 'smile'
}

/** Milliseconds per character as the line types out, and the count-up's length. */
const typeSpeed = 34
const typeDelay = 300
const countDuration = 1200
const offscreenRetry = 500

function easeOut(t: number): number {
	return 1 - (1 - t) ** 3
}

export function HeroDemo({ children }: { readonly children: ReactNode }) {
	const root = useRef<HTMLDivElement>(null)
	const [playing, setPlaying] = useState<boolean | null>(null)

	// Autoplay once the page has settled, unless the visitor asked for reduced motion.
	useEffect(() => {
		const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
		if (reduce) {
			const id = window.requestAnimationFrame(() => setPlaying(false))
			return () => window.cancelAnimationFrame(id)
		}
		return afterLoad(() => setPlaying(true))
	}, [])

	useEffect(() => {
		const el = root.current
		if (!el || !playing) return
		const scope = el.closest<HTMLElement>('[data-hero]') ?? el
		const typed = el.querySelector<HTMLElement>('[data-type]')
		const count = el.querySelector<HTMLElement>('[data-count]')
		const figures = scope.querySelectorAll<SVGElement>('[data-figure] svg')
		const line = typed?.dataset.type ?? ''
		let timer = 0
		let frame = 0
		let visible = true
		let index = 0

		const observer = new IntersectionObserver(([entry]) => {
			visible = entry?.isIntersecting ?? true
		})
		observer.observe(el)

		const countUp = (target: number) => {
			if (!count) return
			const start = performance.now()
			const tick = (now: number) => {
				const t = Math.min(1, (now - start) / countDuration)
				count.textContent = String(Math.round(target * easeOut(t)))
				if (t < 1) frame = window.requestAnimationFrame(tick)
			}
			frame = window.requestAnimationFrame(tick)
		}

		const type = (done: () => void) => {
			if (!typed) return done()
			let shown = 0
			typed.textContent = ''
			const next = () => {
				shown += 1
				typed.textContent = line.slice(0, shown)
				timer = window.setTimeout(shown < line.length ? next : done, typeSpeed)
			}
			timer = window.setTimeout(next, typeDelay)
		}

		const show = () => {
			if (!visible || document.hidden) {
				timer = window.setTimeout(show, offscreenRetry)
				return
			}
			const entry = steps[index % steps.length]
			if (!entry) return
			const [step, hold] = entry
			index += 1
			el.dataset.step = step
			// A figure only takes an expression it has drawn; the others keep their last one.
			for (const figure of figures) {
				if (figure.querySelector(`[data-face='${faces[step]}']`)) figure.dataset.expr = faces[step]
			}
			const advance = () => {
				timer = window.setTimeout(show, hold)
			}
			if (step === 'talk') return type(advance)
			if (step === 'score') countUp(Number(count?.dataset.count ?? 0))
			advance()
		}

		// Resume where the loop was if it was paused mid-way; start with the line otherwise.
		const current = steps.findIndex(([s]) => s === el.dataset.step)
		index = current > 0 ? current + 1 : 0
		timer = window.setTimeout(show, current > 0 ? 600 : 0)

		return () => {
			window.clearTimeout(timer)
			window.cancelAnimationFrame(frame)
			observer.disconnect()
			if (typed) typed.textContent = line
			if (count) count.textContent = count.dataset.count ?? ''
		}
	}, [playing])

	return (
		<div className={styles.demo}>
			<div ref={root} className="tone-ch1" data-step="pick">
				{children}
			</div>
			<button
				type="button"
				className={`button-sm ${styles.toggle}`}
				onClick={() => setPlaying((p) => !p)}
				hidden={playing === null}
			>
				{playing ? <Pause weight="fill" aria-hidden="true" /> : <Play weight="fill" aria-hidden="true" />}
				<span>{playing ? demo.pause : demo.play}</span>
			</button>
		</div>
	)
}
