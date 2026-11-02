import { ArrowUpRight, Cpu, Sparkle } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import { proof, scoring } from '@/content/site'

import styles from './Scoring.module.css'

const tones = ['ch1', 'ch2', 'honey', 'ch3'] as const
const scorerIcons = [Cpu, Sparkle] as const

/** Scoring: the four dimensions and their weights, the two scorers, then the published proof. */
export function Scoring() {
	return (
		<section id="scoring" className={styles.section} aria-labelledby="scoring-title">
			<div className={`container ${styles.grid}`}>
				<div className={styles.intro} data-reveal>
					<p className={`caption-3 ${styles.kicker}`}>{scoring.kicker}</p>
					<h2 id="scoring-title" className="heading-2">
						{scoring.title}
					</h2>
					<p className={`body-3 ${styles.body}`}>{scoring.body}</p>
					<ul className={styles.scorers}>
						{scoring.scorers.map((s, i) => {
							const Icon = scorerIcons[i] ?? Cpu
							return (
								<li key={s.title}>
									<span className={styles.scorerIcon} aria-hidden="true">
										<Icon weight="bold" />
									</span>
									<div>
										<p className={`caption-3 ${styles.scorerKicker}`}>{s.kicker}</p>
										<h3 className="body-1">{s.title}</h3>
										<p className={`body-6 ${styles.muted}`}>{s.body}</p>
									</div>
								</li>
							)
						})}
					</ul>
					<a className={`body-4 ${styles.link}`} href={scoring.readMore.href}>
						{scoring.readMore.label}
						<ArrowUpRight weight="bold" aria-hidden="true" />
					</a>
				</div>

				<div className={styles.card} data-reveal>
					<div className={styles.stack} aria-hidden="true">
						{scoring.dimensions.map((d, i) => (
							<span
								key={d.name}
								className={styles[tones[i] ?? 'ch1']}
								style={{ '--w': d.weight } as CSSProperties}
							/>
						))}
					</div>
					<ul className={styles.dimensions}>
						{scoring.dimensions.map((d, i) => (
							<li key={d.name}>
								<span className={`${styles.dot} ${styles[tones[i] ?? 'ch1'] ?? ''}`} aria-hidden="true" />
								<div>
									<h3 className="heading-6">{d.name}</h3>
									<p className={`body-6 ${styles.muted}`}>{d.question}</p>
								</div>
								<p className={styles.weight}>
									<span className="heading-5 tnum">{d.weight}%</span>
									<span className={`caption-4 ${styles.muted}`}>{scoring.weightLabel}</span>
								</p>
							</li>
						))}
					</ul>
				</div>
			</div>

			<div className={`container ${styles.proof}`} data-reveal>
				<div className={styles.proofHead}>
					<p className={`caption-3 ${styles.kicker}`}>{proof.kicker}</p>
					<h2 className="heading-3">{proof.title}</h2>
					<p className={`body-3 ${styles.body}`}>{proof.body}</p>
				</div>
				<dl className={styles.stats}>
					{proof.stats.map((s) => (
						<div key={s.label}>
							<dt className={`body-6 ${styles.muted}`}>{s.label}</dt>
							<dd className="heading-2 tnum">{s.value}</dd>
						</div>
					))}
				</dl>
				<div className={styles.limits}>
					<h3 className="body-1">{proof.limitsTitle}</h3>
					<ul>
						{proof.limits.map((l) => (
							<li key={l} className="body-6">
								{l}
							</li>
						))}
					</ul>
					<p className={`caption-4 ${styles.muted}`}>
						{proof.date} ·{' '}
						<a className={styles.inlineLink} href={proof.source.href}>
							{proof.source.label}
						</a>
					</p>
				</div>
			</div>
		</section>
	)
}
