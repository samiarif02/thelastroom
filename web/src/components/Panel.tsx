import { Ear } from '@phosphor-icons/react/dist/ssr'

import { Figure } from '@/cast/Figure'
import { panel } from '@/content/site'

import styles from './Panel.module.css'

/**
 * Meet the panel (mockup 10): the intro and the three steps of a room on the left; the four
 * interviewers on the right in a staggered 2 × 2, each in an arch on their colour, with a line
 * they say in the game. Hover or focus a card and they react.
 */
export function Panel() {
	return (
		<section id="panel" className={styles.section} aria-labelledby="panel-title">
			<div className={`container ${styles.grid}`}>
				<div className={styles.intro} data-reveal>
					<h2 id="panel-title" className="heading-3">
						{panel.title}
					</h2>
					<p className={`body-3 ${styles.body}`}>{panel.body}</p>
					<ol className={styles.steps}>
						{panel.steps.map((step, i) => (
							<li key={step.title}>
								<span className={`button-sm ${styles.number}`} aria-hidden="true">
									{i + 1}
								</span>
								<p className="body-3">
									<strong className={styles.stepTitle}>{step.title}</strong> {step.body}
								</p>
							</li>
						))}
					</ol>
				</div>
				<ul className={styles.people}>
					{panel.people.map((p, i) => (
						<li
							key={p.name}
							className={`react-host ${styles.person} ${styles[p.tone] ?? ''}`}
							data-reveal
							data-reveal-index={i}
						>
							<div className={styles.pic}>
								<Figure person={p.person} expression={p.rest} hover={p.hover} blinkDelay={i * 900} />
							</div>
							<div className={styles.name}>
								<h3 className="heading-6">{p.name}</h3>
								<p className={`caption-4 ${styles.role}`}>{p.role}</p>
							</div>
							<p className={`body-5 ${styles.line}`}>{p.line}</p>
							<p className={`caption-4 ${styles.listens}`}>
								<Ear weight="bold" aria-hidden="true" />
								{panel.listensLabel}: {p.listens}
							</p>
						</li>
					))}
				</ul>
			</div>
		</section>
	)
}
