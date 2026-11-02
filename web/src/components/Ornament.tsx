import styles from './Ornament.module.css'

type OrnamentProps = {
	/** `center` for the hero and footer, `start` beside left-aligned headings. */
	readonly align?: 'center' | 'start'
	/** Extra layout from the parent (the hero moves it to the left on wide screens). */
	readonly className?: string | undefined
}

/** The title card's brass rule: two hairlines and a diamond. Decorative only. */
export function Ornament({ align = 'center', className }: OrnamentProps) {
	return (
		<span className={`${styles.ornament} ${align === 'start' ? styles.start : ''} ${className ?? ''}`} aria-hidden="true">
			<span className={styles.rule} />
			<span className={styles.diamond} />
			<span className={styles.rule} />
		</span>
	)
}
