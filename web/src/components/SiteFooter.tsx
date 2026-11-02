import Link from 'next/link'

import { footer, site } from '@/content/site'

import { BrandMark } from './BrandMark'
import styles from './SiteFooter.module.css'

export function SiteFooter() {
	return (
		<footer className={styles.footer}>
			<div className={`container ${styles.grid}`}>
				<div>
					<BrandMark />
					<p className={`body-6 ${styles.muted}`}>{footer.line}</p>
				</div>
				<nav aria-label="Footer">
					<ul className={styles.links}>
						{footer.links.map((link) => (
							<li key={link.href}>
								{link.href.startsWith('/') ? (
									<Link className={`body-5 ${styles.link}`} href={link.href}>
										{link.label}
									</Link>
								) : (
									<a className={`body-5 ${styles.link}`} href={link.href}>
										{link.label}
									</a>
								)}
							</li>
						))}
					</ul>
				</nav>
				<p className={`caption-4 ${styles.note}`}>
					{footer.note} © {site.year} {site.name}
				</p>
			</div>
		</footer>
	)
}
