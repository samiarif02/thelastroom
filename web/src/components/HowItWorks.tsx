import { howItWorks } from '@/content/site'

import { PhoneFrame } from './PhoneFrame'
import { SectionHeading } from './SectionHeading'
import styles from './HowItWorks.module.css'

/** A mission in three steps, each with the app's roman numeral and a still. */
export function HowItWorks() {
	return (
		<section id="how-it-works" className={styles.section} aria-labelledby="how-it-works-title">
			<div className="container">
				<SectionHeading
					id="how-it-works-title"
					eyebrow={howItWorks.eyebrow}
					title={howItWorks.title}
					intro={howItWorks.intro}
				/>
				<ol className={styles.steps}>
					{howItWorks.steps.map((step) => (
						<li key={step.numeral} className={styles.step}>
							<PhoneFrame
								still={step.still}
								sizes="(min-width: 60rem) 240px, (min-width: 40rem) 220px, 66vw"
								className={styles.still}
							/>
							<div className={styles.text}>
								<span className={styles.numeral} aria-hidden="true">
									{step.numeral}.
								</span>
								<h3 className={styles.title}>{step.title}</h3>
								<p className={styles.body}>{step.body}</p>
							</div>
						</li>
					))}
				</ol>
			</div>
		</section>
	)
}
