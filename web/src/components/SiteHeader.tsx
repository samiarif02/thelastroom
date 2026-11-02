import { nav, site } from '@/content/site'

import styles from './SiteHeader.module.css'

/** The sticky top bar: the monogram and name, the section links (hidden on phones), GitHub. */
export function SiteHeader() {
	return (
		<header className={styles.header}>
			<div className={`container ${styles.bar}`}>
				<a href="#top" className={styles.brand}>
					<span className={styles.monogram} aria-hidden="true">
						LR
					</span>
					<span className={styles.name}>{site.name}</span>
				</a>
				<nav aria-label="Sections" className={styles.nav}>
					<ul className={styles.links}>
						{nav.map((item) => (
							<li key={item.href}>
								<a href={item.href} className={styles.link}>
									{item.label}
								</a>
							</li>
						))}
					</ul>
				</nav>
				<a href={site.repo} className={styles.github}>
					GitHub
				</a>
			</div>
		</header>
	)
}
