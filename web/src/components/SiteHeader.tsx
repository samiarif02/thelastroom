import { nav, site } from '@/content/site'

import { LiftIndicator } from './LiftIndicator'
import styles from './SiteHeader.module.css'

/** The sticky top bar: the name, the floors (hidden on phones), and the lift's floor indicator. */
export function SiteHeader() {
	return (
		<header className={styles.header}>
			<div className={`container ${styles.bar}`}>
				<a href="#top" className={styles.brand}>
					{site.name}
				</a>
				<nav aria-label="Sections" className={styles.nav}>
					<ul className={styles.links}>
						{nav.map((item) => (
							<li key={item.href}>
								<a href={item.href} className={`label ${styles.link}`}>
									{item.label}
								</a>
							</li>
						))}
					</ul>
				</nav>
				<LiftIndicator />
			</div>
		</header>
	)
}
