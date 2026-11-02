import type { Expression, Person } from '@/cast/people'

import { AnswerCards, Bubble, Dock, MissionBar, RoomStage, SoFar, StatusBar } from './parts'
import styles from './screens.module.css'

type MissionScreenProps = {
	readonly person: Person
	readonly expression: Expression
	readonly also?: readonly Expression[]
	readonly beats: readonly string[]
	readonly beat: number
	readonly speaker: string
	readonly line: string
	readonly soFar?: { readonly beat: string; readonly line: string }
	readonly pick: string
	readonly pickHint: string
	readonly options: readonly string[]
	readonly chosen: number
	readonly lock: string
	/** The hero demo types the line out and changes the interviewer's expression. */
	readonly demo?: boolean
}

/** A floor 1 room: the interviewer at the desk, the line, three answer cards (02-answer). */
export function MissionScreen(props: MissionScreenProps) {
	return (
		<div className={`${styles.screen} ${styles.tinted}`}>
			<StatusBar />
			<MissionBar beats={props.beats} current={props.beat} />
			<div className={styles.stage}>
				<RoomStage
					person={props.person}
					expression={props.expression}
					also={props.also ?? []}
					{...(props.demo ? { figureHook: 'room' } : {})}
				/>
				<Bubble speaker={props.speaker} line={props.line} typed={props.demo ?? false} />
			</div>
			{props.soFar ? <SoFar beat={props.soFar.beat} line={props.soFar.line} /> : null}
			<AnswerCards title={props.pick} hint={props.pickHint} options={props.options} chosen={props.chosen} />
			<Dock label={props.lock} />
		</div>
	)
}
