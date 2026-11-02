import Image from 'next/image'

import type { Exhibit } from '@/content/site'

import styles from './PhoneFrame.module.css'

type PhoneFrameProps = {
	readonly still: Exhibit
	/** The responsive `sizes` hint: how wide the frame is drawn at each breakpoint. */
	readonly sizes: string
	/**
	 * True only for the hero's still: loaded straight away, but not preloaded. On a phone it sits
	 * below the fold, and the headline and text are what should win the bandwidth.
	 */
	readonly eager?: boolean
	readonly className?: string | undefined
}

/** A still from the app in a phone drawn with CSS, with its typed exhibit caption underneath. */
export function PhoneFrame({ still, sizes, eager = false, className }: PhoneFrameProps) {
	return (
		<figure className={`${styles.figure} ${className ?? ''}`}>
			<div className={styles.phone}>
				<div className={styles.screen}>
					<Image
						src={still.src}
						alt={still.alt}
						width={still.width}
						height={still.height}
						sizes={sizes}
						loading={eager ? 'eager' : 'lazy'}
						className={styles.image}
					/>
				</div>
			</div>
			<figcaption className={`label ${styles.caption}`}>{still.caption}</figcaption>
		</figure>
	)
}
