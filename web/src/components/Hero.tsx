import { Lightning } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import { Figure } from '@/cast/Figure'
import { demo, hero } from '@/content/site'

import { HeroDemo } from './HeroDemo'
import styles from './Hero.module.css'
import { DebriefScreen } from './phone/DebriefScreen'
import { MissionScreen } from './phone/MissionScreen'
import { Phone } from './phone/Phone'
import { TowerScreen } from './phone/TowerScreen'
import { WhySheet } from './phone/WhySheet'
import { PrimaryCta } from './PrimaryCta'

/** The skyline through the big arch: x, width and height of each building. */
const city: readonly (readonly [number, number, number])[] = [
	[0, 48, 88],
	[52, 60, 150],
	[116, 40, 70],
	[160, 64, 120],
	[228, 52, 90],
	[284, 56, 160],
	[344, 40, 100]
]

/** The score chip's ring: radius 19 in a 48 box. */
const chipRadius = 19
const chipLength = 2 * Math.PI * chipRadius

export function Hero() {
	return (
		<section className={styles.hero} aria-labelledby="hero-title" data-hero>
			<div className={`container ${styles.grid}`}>
				<div className={styles.copy}>
					<p className={`caption-3 ${styles.kicker}`}>
						<span aria-hidden="true" />
						{hero.kicker}
					</p>
					<h1 id="hero-title" className={`heading-1 hero-heading ${styles.title}`}>
						{hero.title.map((part) => (
							<span key={part}>{part} </span>
						))}
					</h1>
					<p className={`title-1 ${styles.sub}`}>{hero.body}</p>
					<PrimaryCta className={styles.cta} />
					<dl className={styles.proof}>
						{hero.proof.map((item) => (
							<div key={item.label}>
								<dt className={`caption-4 ${styles.proofLabel}`}>{item.label}</dt>
								<dd className={`heading-3 tnum ${styles.proofValue}`}>{item.value}</dd>
							</div>
						))}
					</dl>
				</div>

				<div className={styles.visual}>
					<div className={styles.arch} role="img" aria-label={hero.art.label}>
						<div className={styles.sky}>
							{city.map(([left, width, height]) => (
								<i key={left} style={{ left, width, height } satisfies CSSProperties} />
							))}
						</div>
						<div className={styles.who} data-figure="hero">
							<Figure person="marcus" expression="listening" also={['talk', 'nod', 'smile']} />
						</div>
					</div>

					<div className={`${styles.chip} ${styles.say}`} aria-hidden="true">
						<p className={`caption-3 ${styles.chipSpeaker}`}>{hero.art.speaker}</p>
						<p className="body-2">{hero.art.line}</p>
					</div>
					<div className={`${styles.chip} ${styles.score}`} aria-hidden="true">
						<svg viewBox="0 0 48 48" className={styles.chipRing}>
							<circle cx="24" cy="24" r={chipRadius} className={styles.chipTrack} />
							<circle
								cx="24"
								cy="24"
								r={chipRadius}
								className={styles.chipFill}
								style={
									{
										'--ring': chipLength,
										'--ring-left': chipLength * (1 - hero.art.dimensionScore / 100)
									} as CSSProperties
								}
							/>
						</svg>
						<span>
							<span className={`caption-4 ${styles.chipLabel}`}>{hero.art.dimension}</span>
							<span className="heading-6 tnum">{hero.art.dimensionScore}</span>
						</span>
					</div>
					<div className={`button-md ${styles.chip} ${styles.xp}`} aria-hidden="true">
						<Lightning weight="fill" />
						{hero.art.xp}
					</div>

					<div className={styles.phoneSpot}>
						<HeroDemo>
							<Phone label={demo.label} className={styles.phone}>
								<MissionScreen
									person="marcus"
									expression="listening"
									also={['talk', 'nod']}
									beats={demo.beats}
									beat={1}
									speaker={demo.speaker}
									line={demo.reaction}
									soFar={demo.soFar}
									pick={demo.pick}
									pickHint={demo.pickHint}
									options={demo.options}
									chosen={demo.chosen}
									lock={demo.lock}
									demo
								/>
								<WhySheet
									question={demo.why.question}
									reason={demo.why.reason}
									verdict={demo.why.verdict}
									reaction={demo.why.reaction}
									next={demo.why.next}
								/>
								<DebriefScreen {...demo.debrief} />
								<TowerScreen {...demo.tower} overlay />
							</Phone>
						</HeroDemo>
					</div>
				</div>
			</div>
		</section>
	)
}
