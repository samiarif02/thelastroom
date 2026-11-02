import type { ReactNode } from 'react'

import styles from './ButtonLink.module.css'

type ButtonLinkProps = {
	readonly href: string
	readonly variant?: 'primary' | 'secondary' | 'text'
	readonly children: ReactNode
}

/** A link styled as the app's engraved plate: solid brass, a brass outline, or a quiet text link. */
export function ButtonLink({ href, variant = 'primary', children }: ButtonLinkProps) {
	return (
		<a href={href} className={`${styles.button} ${styles[variant]}`}>
			{children}
		</a>
	)
}
