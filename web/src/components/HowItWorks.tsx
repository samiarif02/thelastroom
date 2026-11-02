import { howItWorks } from '@/content/site'

import { PhoneFrame } from './PhoneFrame'
import { SignArrow } from './SignArrow'
import styles from './HowItWorks.module.css'

/** Floor 1's main column: how a room works, in three steps, each with its still. */
export function HowItWorks() {
	return (
		<div className={styles.block}>
			<h3 className={`label ${styles.label}`}>{howItWorks.label}</h3>
			<ol className={styles.steps}>
				{howItWorks.steps.map((step, i) => (
					<li key={step.numeral} className={styles.step}>
						<PhoneFrame
							still={step.still}
							sizes="(min-width: 64rem) 220px, (min-width: 48rem) 200px, 40vw"
							className={styles.still}
						/>
						<div className={styles.text}>
							<p className={styles.numeral} aria-hidden="true">
								<span>{step.numeral}</span>
								{i < howItWorks.steps.length - 1 ? <SignArrow className={styles.next} /> : null}
							</p>
							<h4 className={styles.title}>{step.title}</h4>
							<p className={styles.copy}>{step.body}</p>
						</div>
					</li>
				))}
			</ol>
		</div>
	)
}

/** Floor 1's side column: the tower, the app's home screen, which lists the floor's rooms. */
export function TowerStill() {
	return <PhoneFrame still={howItWorks.tower} sizes="(min-width: 64rem) 220px, 56vw" className={styles.sideStill} />
}
