import { Figure } from '@/cast/Figure'
import { finale } from '@/content/site'

import styles from './Finale.module.css'
import { PrimaryCta } from './PrimaryCta'

/**
 * The final call to action, identical to the hero's: on the top floor at dusk, the one place the
 * page goes dark, with the whole panel smiling in lit windows.
 */
export function Finale() {
	return (
		<section id="get" className={styles.section} aria-labelledby="get-title">
			<div className="container">
				<div className={styles.floor} data-reveal>
					<div className={styles.copy}>
						<p className={`caption-3 ${styles.kicker}`}>{finale.kicker}</p>
						<h2 id="get-title" className={`heading-2 ${styles.title}`}>
							{finale.title.map((part) => (
								<span key={part}>{part} </span>
							))}
						</h2>
						<p className={`body-3 ${styles.body}`}>{finale.body}</p>
						<PrimaryCta className={styles.cta} onDark />
					</div>
					<ul className={styles.windows} aria-label="The panel">
						{finale.cast.map((c, i) => (
							<li key={c.person} className={`react-host ${styles.window}`}>
								<Figure
									person={c.person}
									expression={c.expression}
									hover={c.hover}
									blinkDelay={i * 700}
									label={c.person.charAt(0).toUpperCase() + c.person.slice(1)}
								/>
							</li>
						))}
					</ul>
				</div>
			</div>
		</section>
	)
}
