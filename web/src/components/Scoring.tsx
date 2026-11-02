import { scoring } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { SectionHeading } from './SectionHeading'
import styles from './Scoring.module.css'

// The bars are drawn relative to the heaviest dimension, so its bar is full width.
const heaviest = Math.max(...scoring.dimensions.map((d) => d.weight))

/** The four dimensions and their weights, the two scorers, and what the score doesn't claim. */
export function Scoring() {
	return (
		<section id="scoring" className={styles.section} aria-labelledby="scoring-title">
			<div className="container">
				<SectionHeading id="scoring-title" eyebrow={scoring.eyebrow} title={scoring.title} intro={scoring.intro} />
				<div className={styles.grid}>
					<ul className={styles.dimensions} aria-label="The four dimensions and their weights">
						{scoring.dimensions.map((d) => (
							<li key={d.name} className={styles.dimension}>
								<div className={styles.dimensionHead}>
									<h3 className={styles.dimensionName}>{d.name}</h3>
									<span className={styles.weight}>{d.weight}%</span>
								</div>
								<span className={styles.bar} aria-hidden="true">
									<span className={styles.fill} style={{ width: `${(d.weight / heaviest) * 100}%` }} />
								</span>
								<p className={styles.question}>{d.question}</p>
							</li>
						))}
					</ul>
					<div className={styles.side}>
						{scoring.scorers.map((s) => (
							<article key={s.title} className={styles.scorer}>
								<p className={styles.scorerEyebrow}>{s.eyebrow}</p>
								<h3 className={styles.scorerTitle}>{s.title}</h3>
								<p className={styles.body}>{s.body}</p>
							</article>
						))}
					</div>
				</div>
				<div className={styles.limits}>
					<h3 className={styles.limitsTitle}>{scoring.limitsTitle}</h3>
					<ul className={styles.limitList}>
						{scoring.limits.map((limit) => (
							<li key={limit} className={styles.limit}>
								{limit}
							</li>
						))}
					</ul>
					<ButtonLink href={scoring.readMore.href} variant="text">
						{scoring.readMore.label}
					</ButtonLink>
				</div>
			</div>
		</section>
	)
}
