import { ArrowRight, Hash } from '@phosphor-icons/react/dist/ssr'

import { ArchPortrait } from './parts'
import styles from './screens.module.css'

type WhySheetProps = {
	readonly question: string
	readonly reason: string
	readonly verdict: string
	readonly reaction: string
	readonly next: string
}

/** The "why that line?" step's verdict, rising from the bottom (03-why, moment 3). */
export function WhySheet({ question, reason, verdict, reaction, next }: WhySheetProps) {
	return (
		<div className={styles.sheet}>
			<p className={`caption-3 ${styles.sheetKicker}`}>{question}</p>
			<div className={styles.reason}>
				<span className={styles.reasonTile}>
					<Hash weight="bold" />
				</span>
				<p className="body-2">{reason}</p>
			</div>
			<div className={styles.verdict}>
				<ArchPortrait person="marcus" expression="nod" className={styles.verdictArch} />
				<div>
					<p className={`heading-6 ${styles.verdictTitle}`}>{verdict}</p>
					<p className={`body-6 ${styles.muted}`}>{reaction}</p>
				</div>
			</div>
			<span className={styles.sheetButton}>
				{next}
				<ArrowRight weight="bold" />
			</span>
		</div>
	)
}
