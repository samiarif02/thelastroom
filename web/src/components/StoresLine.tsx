import { hero } from '@/content/site'

import styles from './StoresLine.module.css'

/** "Coming soon on Google Play · App Store", typed: text, not the stores' badges (their rules). */
export function StoresLine() {
	return (
		<p className={`label ${styles.stores}`}>
			<span className={styles.status}>{hero.stores.label}</span>{' '}
			{hero.stores.names.map((name, i) => (
				<span key={name}>
					{i > 0 ? <span aria-hidden="true"> · </span> : null}
					<span className={styles.store}>{name}</span>
					{i < hero.stores.names.length - 1 ? <span className="visually-hidden"> and </span> : null}
				</span>
			))}
		</p>
	)
}
