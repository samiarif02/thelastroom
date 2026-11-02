import styles from './SignArrow.module.css'

type SignArrowProps = {
	readonly direction?: 'right' | 'up'
	readonly className?: string | undefined
}

/** A signage arrow: a heavy stroke with square ends, the kind painted on a lobby wall. */
export function SignArrow({ direction = 'right', className }: SignArrowProps) {
	return (
		<svg
			className={`${styles.arrow} ${direction === 'up' ? styles.up : ''} ${className ?? ''}`}
			viewBox="0 0 24 24"
			aria-hidden="true"
			focusable="false"
		>
			<path d="M3 12h16M12 4.5l7.5 7.5-7.5 7.5" />
		</svg>
	)
}
