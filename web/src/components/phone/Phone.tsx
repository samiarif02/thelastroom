import type { ReactNode } from 'react'

import styles from './Phone.module.css'

type PhoneProps = {
	/** What the screen shows, for assistive technology: the phone is one picture. */
	readonly label: string
	/** Sets `--phone-scale` (and so the phone's size) per breakpoint. */
	readonly className?: string | undefined
	readonly children: ReactNode
}

/**
 * A phone drawn in HTML and CSS. The screen is laid out at the app's own size (390 × 844, the
 * mockups' phone) and scaled to fit, so every value inside is the app's value, and the text keeps
 * its real size for the browser (the scale is only a transform).
 */
export function Phone({ label, className, children }: PhoneProps) {
	return (
		<div className={`${styles.device} ${className ?? ''}`} role="img" aria-label={label}>
			<div className={styles.screen}>
				<div className={styles.canvas} aria-hidden="true">
					{children}
				</div>
			</div>
		</div>
	)
}
