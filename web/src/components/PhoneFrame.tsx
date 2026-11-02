import Image from 'next/image'

import type { Still } from '@/content/site'

import styles from './PhoneFrame.module.css'

type PhoneFrameProps = {
	readonly still: Still
	/** The responsive `sizes` hint: how wide the frame is drawn at each breakpoint. */
	readonly sizes: string
	/** True only for the hero's first still, the page's largest paint. */
	readonly preload?: boolean
	readonly className?: string | undefined
}

/** A still from the app inside a slim ink phone with a brass hairline. */
export function PhoneFrame({ still, sizes, preload = false, className }: PhoneFrameProps) {
	return (
		<div className={`${styles.phone} ${className ?? ''}`}>
			<div className={styles.screen}>
				<Image
					src={still.src}
					alt={still.alt}
					width={still.width}
					height={still.height}
					sizes={sizes}
					preload={preload}
					loading={preload ? 'eager' : 'lazy'}
					className={styles.image}
				/>
			</div>
		</div>
	)
}
