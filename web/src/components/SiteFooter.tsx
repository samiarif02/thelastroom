import { footer, hero, site } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { Ornament } from './Ornament'
import styles from './SiteFooter.module.css'

/** The closing call to action, the links, the privacy line and the copyright. */
export function SiteFooter() {
	return (
		<footer className={styles.footer}>
			<div className={`container ${styles.inner}`}>
				<div className={styles.cta}>
					<p className={styles.name}>{site.name}</p>
					<Ornament />
					<p className={styles.line}>{footer.line}</p>
					<ButtonLink href={hero.preview.href}>{hero.preview.label}</ButtonLink>
					<p className={styles.stores}>
						{hero.stores.label} {hero.stores.names.join(' and ')}
					</p>
				</div>
				<nav aria-label="Project links">
					<ul className={styles.links}>
						{footer.links.map((link) => (
							<li key={link.href}>
								<a href={link.href} className={styles.link}>
									{link.label}
								</a>
							</li>
						))}
					</ul>
				</nav>
				<div className={styles.fine}>
					<p>{footer.privacy}</p>
					<p>
						© {site.year} {site.name}. {footer.note}
					</p>
				</div>
			</div>
		</footer>
	)
}
