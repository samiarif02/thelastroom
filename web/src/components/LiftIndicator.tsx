'use client'

import { useEffect, useRef, useState } from 'react'

import styles from './LiftIndicator.module.css'

// The levels the panel can show, bottom to top. Sections say theirs with `data-lift`.
const levels = ['L', '1', '2', '3'] as const
type Level = (typeof levels)[number]

// A section counts as the current floor once its top passes this share of the viewport.
const arrivalLine = 0.4

type Stop = { readonly level: Level; readonly name: string }

const lobby: Stop = { level: 'L', name: 'Lobby' }

function isLevel(value: string | undefined): value is Level {
	return levels.some((level) => level === value)
}

/** Which floor the reader is on: the last section above the arrival line that names a level. */
function currentStop(): Stop {
	let stop = lobby
	let level: Level = 'L'
	for (const node of document.querySelectorAll<HTMLElement>('[data-lift-name]')) {
		if (node.getBoundingClientRect().top > window.innerHeight * arrivalLine) break
		if (isLevel(node.dataset.lift)) level = node.dataset.lift
		stop = { level, name: node.dataset.liftName ?? '' }
	}
	return stop
}

/**
 * The lift panel in the header: the floor number rolls as you scroll up the building, with the
 * arrow lit while it moves. Decorative (the sections have their own headings), so it's hidden from
 * screen readers; with reduced motion the number changes without rolling.
 */
export function LiftIndicator() {
	const [stop, setStop] = useState<Stop>(lobby)
	const [moving, setMoving] = useState<'up' | 'down' | null>(null)
	const previous = useRef<Level>('L')

	useEffect(() => {
		let frame = 0
		let settle = 0
		const update = () => {
			frame = 0
			const next = currentStop()
			setStop((current) => (current.level === next.level && current.name === next.name ? current : next))
			if (next.level !== previous.current) {
				setMoving(levels.indexOf(next.level) > levels.indexOf(previous.current) ? 'up' : 'down')
				previous.current = next.level
				window.clearTimeout(settle)
				settle = window.setTimeout(() => setMoving(null), 900)
			}
		}
		const onScroll = () => {
			if (!frame) frame = window.requestAnimationFrame(update)
		}
		update()
		window.addEventListener('scroll', onScroll, { passive: true })
		window.addEventListener('resize', onScroll)
		return () => {
			window.removeEventListener('scroll', onScroll)
			window.removeEventListener('resize', onScroll)
			window.cancelAnimationFrame(frame)
			window.clearTimeout(settle)
		}
	}, [])

	return (
		<div className={styles.panel} aria-hidden="true">
			<span className={`${styles.arrow} ${moving === 'down' ? styles.down : ''} ${moving ? styles.lit : ''}`} />
			<span className={styles.window}>
				<span className={styles.strip} style={{ transform: `translateY(${-levels.indexOf(stop.level) * 100}%)` }}>
					{levels.map((level) => (
						<span key={level} className={styles.level}>
							{level}
						</span>
					))}
				</span>
			</span>
			<span className={`label ${styles.name}`}>{stop.name}</span>
		</div>
	)
}
