import styles from './BrandMark.module.css'

/** The logo: an arched window with a honey door, and the name. */
export function BrandMark({ withName = true }: { readonly withName?: boolean }) {
	return (
		<span className={styles.brand}>
			<span className={styles.mark} aria-hidden="true" />
			{withName ? <span className={styles.name}>The Last Room</span> : null}
		</span>
	)
}
