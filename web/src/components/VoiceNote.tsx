import { voice } from '@/content/site'

import { PhoneFrame } from './PhoneFrame'
import styles from './VoiceNote.module.css'

/** Floor 2's main column: how a spoken answer works, beside the recorder. */
export function VoiceNote() {
	return (
		<div className={styles.note}>
			<PhoneFrame still={voice.still} sizes="(min-width: 48rem) 220px, 56vw" className={styles.still} />
			<div className={styles.text}>
				<h3 className={`label ${styles.label}`}>{voice.label}</h3>
				<p className={styles.title}>{voice.title}</p>
				{voice.body.map((paragraph) => (
					<p key={paragraph} className={styles.copy}>
						{paragraph}
					</p>
				))}
			</div>
		</div>
	)
}
