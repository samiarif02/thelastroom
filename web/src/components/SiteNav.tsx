'use client'

import { type CSSProperties, useEffect, useRef, useState } from 'react'

import { nav } from '@/content/site'

import { BrandMark } from './BrandMark'
import styles from './SiteNav.module.css'

// The floating nav (landing-page-design B7): centred, translucent and blurred, sized to its
// content. The link for the section in view is highlighted. On a phone, a menu tile opens a
// full-height panel whose links arrive 60 ms apart; the tile's lines turn into a cross.

/** The line, as a fraction of the viewport from the top, that decides which section is current. */
const currentLine = 0.35

export function SiteNav() {
	const [open, setOpen] = useState(false)
	const [current, setCurrent] = useState<string | null>(null)
	const toggle = useRef<HTMLButtonElement>(null)

	useEffect(() => {
		const targets = nav.links
			.map((link) => document.querySelector<HTMLElement>(link.href))
			.filter((el): el is HTMLElement => el !== null)
		const visible = new Set<string>()
		const observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) {
					const id = `#${entry.target.id}`
					if (entry.isIntersecting) visible.add(id)
					else visible.delete(id)
				}
				// The last section in page order that crosses the line.
				const hit = nav.links.findLast((link) => visible.has(link.href))
				setCurrent(hit?.href ?? null)
			},
			{ rootMargin: `-${currentLine * 100}% 0px -${(1 - currentLine) * 100 - 1}% 0px` }
		)
		for (const el of targets) observer.observe(el)
		return () => observer.disconnect()
	}, [])

	useEffect(() => {
		if (!open) return
		const onKey = (event: KeyboardEvent) => {
			if (event.key === 'Escape') {
				setOpen(false)
				toggle.current?.focus()
			}
		}
		document.addEventListener('keydown', onKey)
		document.documentElement.classList.add(styles.locked ?? '')
		return () => {
			document.removeEventListener('keydown', onKey)
			document.documentElement.classList.remove(styles.locked ?? '')
		}
	}, [open])

	return (
		<header className={styles.header}>
			<nav className={styles.bar} aria-label="Main">
				<a className={styles.home} href="#top" aria-label={nav.home}>
					<BrandMark />
				</a>
				<ul className={styles.links}>
					{nav.links.map((link) => (
						<li key={link.href}>
							<a
								className={`body-5 ${styles.link}`}
								href={link.href}
								aria-current={current === link.href ? 'location' : undefined}
							>
								{link.label}
							</a>
						</li>
					))}
				</ul>
				<a className={`button-sm ${styles.cta}`} href={nav.cta.href}>
					{nav.cta.label}
				</a>
				<button
					ref={toggle}
					type="button"
					className={styles.menuButton}
					aria-expanded={open}
					aria-controls="menu"
					aria-label={open ? nav.close : nav.open}
					onClick={() => setOpen((o) => !o)}
				>
					<span className={styles.lines} aria-hidden="true">
						<span />
						<span />
						<span />
					</span>
				</button>
			</nav>
			<div id="menu" className={styles.panel} data-open={open} hidden={!open}>
				<ul>
					{[...nav.links, nav.cta].map((link, i) => (
						<li key={link.href} style={{ '--i': i } as CSSProperties}>
							<a
								className={`heading-3 ${styles.panelLink}`}
								href={link.href}
								onClick={() => setOpen(false)}
								aria-current={current === link.href ? 'location' : undefined}
							>
								{link.label}
							</a>
						</li>
					))}
				</ul>
			</div>
		</header>
	)
}
