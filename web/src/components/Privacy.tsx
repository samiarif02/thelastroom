import { privacy } from '@/content/site'

import { Sign } from './Sign'
import styles from './Privacy.module.css'

/** House rules: no sign-up, progress on the phone, voice not stored. */
export function Privacy() {
	return (
		<section
			id="privacy"
			className="section"
			aria-labelledby="privacy-title"
			data-tone="neutral"
			data-lift-name={privacy.label}
		>
			<div className={`container ${styles.layout}`}>
				<Sign id="privacy-title" mark={privacy.mark} label={privacy.label} title={privacy.title} aside={privacy.aside} />
				<ol className={styles.rules}>
					{privacy.points.map((point, i) => (
						<li key={point.title} className={styles.rule}>
							<span className={`label ${styles.index}`} aria-hidden="true">
								{`Rule ${i + 1}`}
							</span>
							<h3 className={styles.title}>{point.title}</h3>
							<p className={styles.copy}>{point.body}</p>
						</li>
					))}
				</ol>
			</div>
		</section>
	)
}
