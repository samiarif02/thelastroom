import { privacy } from '@/content/site'

import { SectionHeading } from './SectionHeading'
import styles from './Privacy.module.css'

/** No sign-up, progress on the phone, voice not stored. */
export function Privacy() {
	return (
		<section id="privacy" className={styles.section} aria-labelledby="privacy-title">
			<div className="container">
				<SectionHeading id="privacy-title" eyebrow={privacy.eyebrow} title={privacy.title} />
				<ul className={styles.points}>
					{privacy.points.map((point, i) => (
						<li key={point.title} className={styles.point}>
							<span className={styles.index} aria-hidden="true">
								{String(i + 1).padStart(2, '0')}
							</span>
							<h3 className={styles.title}>{point.title}</h3>
							<p className={styles.body}>{point.body}</p>
						</li>
					))}
				</ul>
			</div>
		</section>
	)
}
