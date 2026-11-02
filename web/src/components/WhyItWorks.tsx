import { whyItWorks } from '@/content/site'

import { PhoneFrame } from './PhoneFrame'
import { SectionHeading } from './SectionHeading'
import styles from './WhyItWorks.module.css'

/** The learning: what each mission names, the Recall Room's spacing, the baseline, no autopilot. */
export function WhyItWorks() {
	return (
		<section id="why-it-works" className={styles.section} aria-labelledby="why-it-works-title">
			<div className={`container ${styles.grid}`}>
				<div>
					<SectionHeading
						id="why-it-works-title"
						eyebrow={whyItWorks.eyebrow}
						title={whyItWorks.title}
						intro={whyItWorks.intro}
					/>
					<ul className={styles.reasons}>
						{whyItWorks.reasons.map((reason) => (
							<li key={reason.title} className={styles.reason}>
								<h3 className={styles.title}>{reason.title}</h3>
								<p className={styles.body}>{reason.body}</p>
							</li>
						))}
					</ul>
				</div>
				<PhoneFrame
					still={whyItWorks.still}
					sizes="(min-width: 60rem) 280px, (min-width: 40rem) 240px, 62vw"
					className={styles.still}
				/>
			</div>
		</section>
	)
}
