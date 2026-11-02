import { scoring } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { Sign } from './Sign'
import styles from './Scoring.module.css'

// The bars are drawn against the whole score, so four of them side by side make 100.
const total = scoring.dimensions.reduce((sum, d) => sum + d.weight, 0)

/**
 * The notice board, in concrete: how an answer is weighed (four dimensions adding up to 100), the
 * two scorers, and what the score doesn't claim, posted like notices in a building.
 */
export function Scoring() {
	return (
		<section
			id="scoring"
			className="section light"
			aria-labelledby="scoring-title"
			data-tone="neutral"
			data-lift-name={scoring.label}
		>
			<div className={`container ${styles.layout}`}>
				<Sign
					id="scoring-title"
					mark={scoring.mark}
					label={scoring.label}
					title={scoring.title}
					aside={scoring.aside}
					intro={scoring.intro}
				/>
				<div className={styles.board}>
					<div className={styles.notice}>
						<p className={`label ${styles.noticeHead}`}>
							<span>{scoring.board.title}</span>
							<span>{scoring.board.total}</span>
						</p>
						<p className={styles.split} aria-hidden="true">
							{scoring.dimensions.map((d) => (
								<span key={d.name} className={styles.segment} style={{ flexGrow: d.weight / total }}>
									{d.weight}
								</span>
							))}
						</p>
						<ul className={styles.dimensions}>
							{scoring.dimensions.map((d) => (
								<li key={d.name} className={styles.dimension}>
									<p className={styles.weight}>
										{d.weight}
										<span className={styles.unit}>%</span>
									</p>
									<div>
										<h3 className={styles.name}>{d.name}</h3>
										<p className={styles.question}>{d.question}</p>
									</div>
								</li>
							))}
						</ul>
					</div>
					<div className={styles.scorers}>
						{scoring.scorers.map((s) => (
							<article key={s.title} className={styles.notice}>
								<p className={`label ${styles.noticeHead}`}>
									<span>{s.eyebrow}</span>
								</p>
								<div className={styles.noticeBody}>
									<h3 className={styles.scorerTitle}>{s.title}</h3>
									<p className={styles.copy}>{s.body}</p>
								</div>
							</article>
						))}
					</div>
					<div className={`${styles.notice} ${styles.limits}`}>
						<h3 className={`label ${styles.noticeHead}`}>{scoring.limitsTitle}</h3>
						<ol className={styles.limitList}>
							{scoring.limits.map((limit, i) => (
								<li key={limit} className={styles.limit}>
									<span className={`label ${styles.limitIndex}`} aria-hidden="true">
										{String(i + 1).padStart(2, '0')}
									</span>
									<p>{limit}</p>
								</li>
							))}
						</ol>
						<div className={styles.readMore}>
							<ButtonLink href={scoring.readMore.href} variant="text">
								{scoring.readMore.label}
							</ButtonLink>
						</div>
					</div>
				</div>
			</div>
		</section>
	)
}
