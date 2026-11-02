import type { Metadata } from 'next'
import Link from 'next/link'

import { Figure } from '@/cast/Figure'
import { BrandMark } from '@/components/BrandMark'
import { notFound, site } from '@/content/site'

import styles from './not-found.module.css'

export const metadata: Metadata = {
	title: `${notFound.title} · ${site.name}`,
	robots: { index: false }
}

/** The branded 404: Priya, puzzled, and the way back down. */
export default function NotFound() {
	return (
		<main id="main" className={`container ${styles.main}`}>
			<Link className={styles.home} href="/">
				<BrandMark />
			</Link>
			<div className={styles.grid}>
				<div className={`tone-ch1 ${styles.arch}`}>
					<Figure person="priya" expression="thinking" label="Priya, the recruiter, looking puzzled" />
				</div>
				<div>
					<p className={`caption-3 ${styles.kicker}`}>{notFound.kicker}</p>
					<h1 className="heading-1">{notFound.title}</h1>
					<p className={`title-1 ${styles.body}`}>{notFound.body}</p>
					<Link className={`button-lg ${styles.button}`} href="/">
						{notFound.back}
					</Link>
				</div>
			</div>
		</main>
	)
}
