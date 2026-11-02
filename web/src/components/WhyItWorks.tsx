import { whyItWorks } from '@/content/site'

import { PhoneFrame } from './PhoneFrame'
import { Sign } from './Sign'
import styles from './WhyItWorks.module.css'

// The Recall Room's spacing drawn to scale, from the day you fell for the trap to the last return.
const lastDay = Math.max(...whyItWorks.recall.days)

/** The Recall Room: why the game teaches. Four reasons, a Recall Room card and its 1, 3, 7 days. */
export function WhyItWorks() {
	return (
		<section
			id="recall-room"
			className="section"
			aria-labelledby="recall-room-title"
			data-tone="neutral"
			data-lift-name={whyItWorks.label}
		>
			<div className={`container ${styles.layout}`}>
				<Sign
					id="recall-room-title"
					mark={whyItWorks.mark}
					label={whyItWorks.label}
					title={whyItWorks.title}
					aside={whyItWorks.aside}
					intro={whyItWorks.intro}
				/>
				<div className={styles.grid}>
					<ol className={styles.reasons}>
						{whyItWorks.reasons.map((reason, i) => (
							<li key={reason.title} className={styles.reason}>
								<span className={`label ${styles.index}`} aria-hidden="true">
									{`R.${i + 1}`}
								</span>
								<div>
									<h3 className={styles.title}>{reason.title}</h3>
									<p className={styles.text}>{reason.body}</p>
								</div>
							</li>
						))}
					</ol>
					<div className={styles.exhibit}>
						<PhoneFrame still={whyItWorks.still} sizes="(min-width: 48rem) 220px, 56vw" className={styles.still} />
						<div className={styles.recall}>
							<p className={`label ${styles.recallLabel}`}>{whyItWorks.recall.label}</p>
							<ol className={styles.timeline}>
								{whyItWorks.recall.days.map((day) => (
									<li key={day} className={styles.day} style={{ left: `${(day / lastDay) * 100}%` }}>
										<span className="label">{`Day ${day}`}</span>
									</li>
								))}
							</ol>
						</div>
					</div>
				</div>
			</div>
		</section>
	)
}
