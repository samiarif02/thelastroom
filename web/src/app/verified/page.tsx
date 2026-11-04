import type { Metadata } from 'next'
import Link from 'next/link'

import { Figure } from '@/cast/Figure'
import { BrandMark } from '@/components/BrandMark'
import { site, verified } from '@/content/site'

import styles from './verified.module.css'

export const metadata: Metadata = {
	title: `${verified.title} · ${site.name}`,
	robots: { index: false, follow: false }
}

/** The app's own link scheme (the Android intent filter / iOS URL type). Harmless when the app
 * isn't installed: the browser just stays here. */
const appLink = 'thelastroom://'

/**
 * Runs before the page paints, with no framework: Supabase redirects an expired or used link
 * here with `#error=…&error_description=…` (or the same in the query), so the page switches to
 * the calm "expired" copy. Then it drops whatever Supabase put in the URL (an auth code, a
 * token, the error), so nothing lingers in the address bar or the history.
 */
const readLink = `(function(){try{var h=location.hash.slice(1),q=location.search.slice(1),p=new URLSearchParams(h+'&'+q);if(p.get('error')||p.get('error_code')||p.get('error_description')){document.documentElement.setAttribute('data-link','expired')}if(h||q){history.replaceState(null,'',location.pathname)}}catch(e){}})()`

/** "You're verified": where "Save your progress"'s email link lands (FR-3). Priya, smiling. */
export default function Verified() {
	return (
		<main id="main" className={`container ${styles.main}`}>
			<script dangerouslySetInnerHTML={{ __html: readLink }} />
			<Link className={styles.home} href="/">
				<BrandMark />
			</Link>
			<div className={styles.grid}>
				<div className={`tone-ch1 ${styles.arch}`}>
					<div className={styles.ok}>
						<Figure person="priya" expression="smile" label="Priya, the recruiter, smiling" />
					</div>
					<div className={styles.expired}>
						<Figure person="priya" expression="thinking" label="Priya, the recruiter, thinking" />
					</div>
				</div>
				<div>
					<div className={styles.ok} role="status">
						<p className={`caption-3 ${styles.kicker}`}>{verified.kicker}</p>
						<h1 className={`heading-1 ${styles.heading}`}>{verified.heading}</h1>
						<p className={`title-1 ${styles.body}`}>{verified.body}</p>
						<a className={`button-lg ${styles.button}`} href={appLink}>
							{verified.open}
						</a>
						<p className={`body-2 ${styles.desktop}`}>{verified.desktop}</p>
					</div>
					<div className={styles.expired} role="status">
						<p className={`caption-3 ${styles.kicker}`}>{verified.expiredKicker}</p>
						<h1 className={`heading-1 ${styles.heading}`}>{verified.expiredHeading}</h1>
						<p className={`title-1 ${styles.body}`}>{verified.expiredBody}</p>
						<a className={`button-lg ${styles.button}`} href={appLink}>
							{verified.open}
						</a>
						<p className={`body-2 ${styles.desktop}`}>
							<Link href="/">{verified.home}</Link>
						</p>
					</div>
				</div>
			</div>
		</main>
	)
}
