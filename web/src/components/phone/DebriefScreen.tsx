import { Lightbulb, Lightning } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import { Dock, StatusBar, TitleBar, ArchPortrait } from './parts'
import styles from './screens.module.css'

/** The score dial's circle: radius 48 in a 112 box. */
const dialRadius = 48
const dialLength = 2 * Math.PI * dialRadius

type DebriefScreenProps = {
	readonly kicker: string
	readonly mission: string
	readonly speaker: string
	readonly line: string
	readonly total: number
	readonly outOf: string
	readonly verdict: string
	readonly scorer: string
	readonly xp: string
	readonly dimensions: readonly { readonly name: string; readonly score: number }[]
	readonly weakest: string
	readonly cta: string
}

/** The debrief (05-debrief): the interviewer's verdict, the dial, four dimensions, the CTA. */
export function DebriefScreen(props: DebriefScreenProps) {
	return (
		<div className={`${styles.screen} ${styles.overlay} ${styles.debrief}`}>
			<StatusBar />
			<TitleBar kicker={props.kicker} title={props.mission} />
			<div className={styles.verdictRow}>
				<ArchPortrait person="marcus" expression="smile" className={styles.debriefArch} />
				<div className={styles.verdictBubble}>
					<p className={`caption-3 ${styles.speakerDeep}`}>{props.speaker}</p>
					<p className="body-2">{props.line}</p>
				</div>
			</div>
			<div className={styles.scoreCard}>
				<div className={styles.scoreTop}>
					<div className={styles.dial}>
						<svg viewBox="0 0 112 112">
							<circle cx="56" cy="56" r={dialRadius} className={styles.dialTrack} />
							<circle
								cx="56"
								cy="56"
								r={dialRadius}
								className={styles.dialFill}
								style={
									{
										'--dial': dialLength,
										'--dial-left': dialLength * (1 - props.total / 100)
									} as CSSProperties
								}
							/>
						</svg>
						<span className={styles.dialText}>
							<span className="heading-2 tnum" data-count={props.total}>
								{props.total}
							</span>
							<span className={`caption-4 ${styles.muted}`}>{props.outOf}</span>
						</span>
					</div>
					<div className={styles.scoreSide}>
						<p className="heading-6">{props.verdict}</p>
						<span className={`caption-3 ${styles.tag} ${styles.tagSand}`}>{props.scorer}</span>
						<span className={`caption-3 ${styles.tag} ${styles.tagHoney}`}>
							<Lightning weight="fill" />
							{props.xp}
						</span>
					</div>
				</div>
				<ul className={styles.dimensions}>
					{props.dimensions.map((d, i) => (
						<li
							key={d.name}
							className={d.name === props.weakest ? styles.weak : undefined}
							style={{ '--v': d.score / 100, '--i': i } as CSSProperties}
						>
							<span className="title-3">{d.name}</span>
							<span className="body-1 tnum">{d.score}</span>
							<span className={styles.track}>
								<span className={styles.fill} />
							</span>
						</li>
					))}
				</ul>
			</div>
			<Dock label={props.cta} icon={<Lightbulb weight="fill" />} ground="paper" />
		</div>
	)
}
