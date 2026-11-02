import { AndroidLogo, Check } from '@phosphor-icons/react/dist/ssr'

import { cta } from '@/content/site'

import styles from './PrimaryCta.module.css'

/** The page's one action and its risk reversal, identical in the hero and at the end. */
type PrimaryCtaProps = {
	readonly className?: string | undefined
	/** On the dusk floor: the risk line turns light. */
	readonly onDark?: boolean
}

export function PrimaryCta({ className, onDark = false }: PrimaryCtaProps) {
	return (
		<div className={`${styles.wrap} ${onDark ? styles.onDark : ''} ${className ?? ''}`}>
			<a className={`button-lg ${styles.button}`} href={cta.href}>
				<AndroidLogo weight="bold" aria-hidden="true" />
				{cta.label}
			</a>
			<ul className={`body-5 ${styles.risk}`} aria-label="What you don’t need">
				{cta.risk.map((item, i) => (
					<li key={item}>
						<Check weight="bold" aria-hidden="true" />
						<span className={styles.long}>{item}</span>
						<span className={styles.short}>{cta.riskShort[i]}</span>
					</li>
				))}
			</ul>
		</div>
	)
}
