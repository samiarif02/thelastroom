import { ArrowLeft } from '@phosphor-icons/react/dist/ssr'
import Link from 'next/link'

import type { LegalSection } from '@/content/site'

import { BrandMark } from './BrandMark'
import styles from './LegalPage.module.css'
import { SiteFooter } from './SiteFooter'

type LegalPageProps = {
	readonly title: string
	readonly intro: string
	readonly sections: readonly LegalSection[]
	readonly updated: string
}

/** Privacy and terms: one plain column, a way back, the same footer. */
export function LegalPage({ title, intro, sections, updated }: LegalPageProps) {
	return (
		<>
			<header className={`container ${styles.header}`}>
				<Link className={styles.home} href="/">
					<BrandMark />
				</Link>
				<Link className={`body-5 ${styles.back}`} href="/">
					<ArrowLeft weight="bold" aria-hidden="true" />
					Back to the page
				</Link>
			</header>
			<main id="main" className={`container ${styles.main}`}>
				<h1 className="heading-2">{title}</h1>
				<p className={`title-1 ${styles.intro}`}>{intro}</p>
				{sections.map((section) => (
					<section key={section.title} className={styles.section}>
						<h2 className="heading-6">{section.title}</h2>
						{section.body.map((p) => (
							<p key={p} className={`body-3 ${styles.p}`}>
								{p}
							</p>
						))}
					</section>
				))}
				<p className={`caption-4 ${styles.updated}`}>{updated}</p>
			</main>
			<SiteFooter />
		</>
	)
}
