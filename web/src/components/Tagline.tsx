import { CheckCircle, PushPin } from '@phosphor-icons/react/dist/ssr'

import { tagline } from '@/content/site'

import { ArchPortrait } from './phone/parts'
import styles from './Tagline.module.css'

/**
 * The tagline reveal (landing-page-design B11, mockup 10): the benefit in Heading 1, each word
 * lighting from 30% to ink in reading order as it crosses a line on screen (PageMotion). Without
 * JavaScript, under reduced motion and until the section nears the viewport, every word is lit.
 * Beside it, the day 3 return made concrete: a Recall Room note in Marcus's voice.
 */
export function Tagline() {
	const words = tagline.words.split(' ')
	return (
		<section className={styles.section} aria-labelledby="tagline">
			<div className={`container ${styles.grid}`}>
				<div>
					<h2 id="tagline" className={`heading-1 ${styles.words}`} data-tagline aria-label={tagline.words}>
						{words.map((word, i) => (
							<span key={`${word}-${i}`} aria-hidden="true" data-word>
								{word}{' '}
							</span>
						))}
					</h2>
					<p className={`body-3 ${styles.note}`}>{tagline.note}</p>
				</div>

				<figure className={`tone-ch1 ${styles.recall}`} data-reveal>
					<figcaption className="visually-hidden">{tagline.recall.label}</figcaption>
					<span className={styles.tape} aria-hidden="true" />
					<div className={styles.noteHead}>
						<ArchPortrait person="marcus" expression="smile" className={styles.noteArch} />
						<div>
							<p className={`caption-3 ${styles.noteKicker}`}>{tagline.recall.kicker}</p>
							<p className="body-2">{tagline.recall.greeting}</p>
						</div>
					</div>
					<p className={`caption-3 ${styles.fell}`}>
						<PushPin weight="fill" aria-hidden="true" />
						{tagline.recall.fell}
					</p>
					<p className="heading-6">{tagline.recall.principle}</p>
					<p className={`body-6 ${styles.led}`}>{tagline.recall.led}</p>
					<ol className={styles.days}>
						{tagline.recall.days.map((d) => (
							<li key={d.day} className={`caption-3 ${styles[d.state] ?? ''}`}>
								{d.state === 'done' ? <CheckCircle weight="fill" aria-hidden="true" /> : null}
								{d.day}
								{d.state === 'now' ? <span className="visually-hidden">, today</span> : null}
							</li>
						))}
					</ol>
					<p className={`caption-4 ${styles.second}`}>{tagline.recall.day}</p>
				</figure>
			</div>
		</section>
	)
}
