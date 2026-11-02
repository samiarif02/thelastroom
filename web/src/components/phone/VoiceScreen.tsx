import { ArrowCounterClockwise, Ear, LockSimple, Microphone, Pause, Stop } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import { Bubble, RoomStage, StatusBar, TitleBar } from './parts'
import styles from './screens.module.css'

/** The live waveform's bar heights (app px): the first 19 are spoken, the rest still to come. */
const wave = [10, 18, 30, 22, 40, 28, 14, 34, 46, 26, 18, 38, 30, 44, 20, 12, 28, 36, 24, 8, 8, 8, 8, 8, 8, 8]
const spoken = 19

type VoiceScreenProps = {
	readonly room: string
	readonly mission: string
	readonly tag: string
	readonly recording: string
	readonly listening: string
	readonly speaker: string
	readonly line: string
	readonly pointsTitle: string
	readonly pointsHint: string
	readonly points: readonly string[]
	readonly privacy: string
	readonly time: string
	readonly cap: string
	readonly pause: string
	readonly again: string
}

/** A floor 2 room, answered out loud (04-voice): the listening interviewer, points, recorder. */
export function VoiceScreen(props: VoiceScreenProps) {
	return (
		<div className={`${styles.screen} ${styles.tinted}`}>
			<StatusBar />
			<TitleBar
				kicker={props.room}
				title={props.mission}
				aside={
					<span className={`button-sm ${styles.outLoud}`}>
						<Microphone weight="bold" />
						{props.tag}
					</span>
				}
			/>
			<div className={styles.stage}>
				<RoomStage
					person="lena"
					expression="listening"
					tags={
						<>
							<span className={`caption-3 ${styles.roomTag}`}>
								<i className={styles.recDot} />
								{props.recording}
							</span>
							<span className={`caption-3 ${styles.roomTag} ${styles.roomTagDeep}`}>
								<Ear weight="bold" />
								{props.listening}
							</span>
						</>
					}
				/>
				<Bubble speaker={props.speaker} line={props.line} />
			</div>
			<div className={styles.points}>
				<div className={styles.pointsHead}>
					<p className="body-1">{props.pointsTitle}</p>
					<p className={`caption-4 ${styles.muted}`}>{props.pointsHint}</p>
				</div>
				<ol className={styles.pointList}>
					{props.points.map((point, i) => (
						<li key={point}>
							<span className={styles.pointNumber}>{i + 1}</span>
							<span className="body-6">{point}</span>
						</li>
					))}
				</ol>
				<p className={`caption-4 ${styles.privacyLine}`}>
					<LockSimple weight="bold" />
					{props.privacy}
				</p>
			</div>
			<div className={styles.recorder}>
				<div className={styles.recorderTop}>
					<span className={styles.time}>
						<span className="heading-5 tnum">{props.time}</span>
						<span className="caption-4">{props.cap}</span>
					</span>
					<span className={styles.wave}>
						{wave.map((height, i) => (
							<i
								key={i}
								className={i < spoken ? styles.spoken : undefined}
								style={{ '--h': `${height}px`, '--i': i } as CSSProperties}
							/>
						))}
					</span>
					<span className={styles.stop}>
						<Stop weight="fill" />
					</span>
				</div>
				<div className={styles.recorderFoot}>
					<span className="button-sm">
						<Pause weight="bold" />
						{props.pause}
					</span>
					<span className="button-sm">
						<ArrowCounterClockwise weight="bold" />
						{props.again}
					</span>
				</div>
			</div>
		</div>
	)
}
