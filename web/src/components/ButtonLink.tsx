import type { ReactNode } from 'react'

import { SignArrow } from './SignArrow'
import styles from './ButtonLink.module.css'

type ButtonLinkProps = {
	readonly href: string
	readonly variant?: 'primary' | 'text'
	readonly children: ReactNode
}

/** The page's one amber action, like a lift call button, or a quiet signposted link. */
export function ButtonLink({ href, variant = 'primary', children }: ButtonLinkProps) {
	return (
		<a href={href} className={`${styles.button} ${styles[variant]}`}>
			<span>{children}</span>
			<SignArrow className={styles.arrow} />
		</a>
	)
}
