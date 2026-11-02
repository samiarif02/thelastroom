import { footer, hero, site } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { SignArrow } from './SignArrow'
import { StoresLine } from './StoresLine'
import styles from './SiteFooter.module.css'

/** The way out: the line once more, the Android preview, the stores, links and fine print. */
export function SiteFooter() {
	return (
		<footer className={styles.footer}>
			<div className="container">
				<div className={styles.exit}>
					<p className={`label ${styles.label}`}>
						<SignArrow className={styles.exitArrow} />
						{footer.label}
					</p>
					<p className={styles.line}>{footer.line}</p>
					<div className={styles.actions}>
						<ButtonLink href={hero.preview.href}>{hero.preview.label}</ButtonLink>
						<StoresLine />
					</div>
				</div>
				<div className={styles.base}>
					<p className={styles.name}>{site.name}</p>
					<nav aria-label="Project links">
						<ul className={styles.links}>
							{footer.links.map((link) => (
								<li key={link.href}>
									<a href={link.href} className={`label ${styles.link}`}>
										{link.label}
									</a>
								</li>
							))}
						</ul>
					</nav>
					<div className={styles.fine}>
						<p>{footer.privacy}</p>
						<p>{`© ${site.year} ${site.name}. ${footer.note}`}</p>
					</div>
				</div>
			</div>
		</footer>
	)
}
