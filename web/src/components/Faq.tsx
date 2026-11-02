import { faq } from '@/content/site'

import styles from './Faq.module.css'

/** The FAQ as a side-by-side list, not an accordion: plain questions and answers (A7). */
export function Faq() {
	return (
		<section id="faq" className={styles.section} aria-labelledby="faq-title">
			<div className={`container ${styles.grid}`}>
				<div className={styles.head} data-reveal>
					<p className={`caption-3 ${styles.kicker}`}>{faq.kicker}</p>
					<h2 id="faq-title" className="heading-2">
						{faq.title}
					</h2>
				</div>
				<dl className={styles.list}>
					{faq.items.map((item) => (
						<div key={item.q} className={styles.item}>
							<dt className="heading-6">{item.q}</dt>
							<dd className={`body-3 ${styles.answer}`}>{item.a}</dd>
						</div>
					))}
				</dl>
			</div>
		</section>
	)
}
