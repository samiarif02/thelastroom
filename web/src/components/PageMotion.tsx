'use client'

import { useEffect } from 'react'

import { afterLoad } from './afterLoad'

// The page's scroll motion, small vanilla DOM work with IntersectionObserver only (B7: never a
// scroll listener). It renders nothing.
//
// - Reveals: a [data-reveal] element below the fold at load is armed (32 px down, transparent),
//   then rises into place once as it scrolls in, 90 ms after its [data-reveal-index] siblings.
//   Anything already on screen never moves.
// - The tagline (B11): just before the section reaches the screen, its words dim to 30%; each
//   lights in reading order as it crosses a line 60% down the viewport. Until then, and without
//   JavaScript, the words stay lit, so nothing is ever hidden at rest.
//
// - Idle: once the page has loaded and settled, `motion-ready` on <html> starts the cast's
//   breathing, swaying and blinking and the phones' small loops (CSS), off the first paint.
//
// Under reduced motion none of this runs: everything simply shows.

const revealStagger = 90
/** How far past the bottom of the screen the tagline arms (a fraction of the viewport). */
const armMargin = '0px 0px 40% 0px'
/** The line words light at: 40% up from the bottom of the viewport. */
const lightMargin = '0px 0px -40% 0px'
/** Words crossing the line together still light one after another. */
const wordStagger = 70

function onScreen(el: Element): boolean {
	const rect = el.getBoundingClientRect()
	return rect.top < window.innerHeight && rect.bottom > 0
}

function watchReveals(): () => void {
	const observer = new IntersectionObserver(
		(entries) => {
			for (const entry of entries) {
				if (!entry.isIntersecting) continue
				const el = entry.target as HTMLElement
				observer.unobserve(el)
				const index = Number(el.dataset.revealIndex ?? 0)
				el.style.setProperty('--reveal-delay', `${index * revealStagger}ms`)
				el.classList.add('is-in')
				el.classList.remove('is-armed')
			}
		},
		{ rootMargin: '0px 0px -10% 0px' }
	)
	for (const el of document.querySelectorAll<HTMLElement>('[data-reveal]')) {
		if (onScreen(el)) continue
		el.classList.add('is-armed')
		observer.observe(el)
	}
	return () => observer.disconnect()
}

function watchTagline(): () => void {
	const heading = document.querySelector<HTMLElement>('[data-tagline]')
	if (!heading || onScreen(heading)) return () => {}
	const words = [...heading.querySelectorAll<HTMLElement>('[data-word]')]

	const light = new IntersectionObserver(
		(entries) => {
			const crossing = entries.filter((e) => e.isIntersecting).map((e) => e.target as HTMLElement)
			crossing.sort((a, b) => words.indexOf(a) - words.indexOf(b))
			crossing.forEach((word, i) => {
				light.unobserve(word)
				word.style.setProperty('--word-delay', `${i * wordStagger}ms`)
				word.classList.remove('is-dim')
			})
		},
		{ rootMargin: lightMargin }
	)

	const arm = new IntersectionObserver(
		([entry]) => {
			if (!entry?.isIntersecting) return
			arm.disconnect()
			for (const word of words) {
				word.classList.add('is-dim')
				light.observe(word)
			}
		},
		{ rootMargin: armMargin }
	)
	arm.observe(heading)

	return () => {
		arm.disconnect()
		light.disconnect()
	}
}

export function PageMotion() {
	useEffect(() => {
		if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
		const ready = afterLoad(() => document.documentElement.classList.add('motion-ready'))
		const stops = [ready, watchReveals(), watchTagline()]
		return () => {
			for (const stop of stops) stop()
		}
	}, [])
	return null
}
