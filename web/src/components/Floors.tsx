import { Check } from '@phosphor-icons/react/dist/ssr'

import { demo, floors, screens, type Floor } from '@/content/site'

import styles from './Floors.module.css'
import { MissionScreen } from './phone/MissionScreen'
import { Phone } from './phone/Phone'
import { TowerScreen } from './phone/TowerScreen'
import { VoiceScreen } from './phone/VoiceScreen'

function FloorScreen({ floor }: { readonly floor: Floor }) {
	switch (floor.screen) {
		case 'answer':
			return (
				<Phone label={screens.answer.label} className={styles.phone}>
					<MissionScreen person="priya" expression="listening" beat={0} {...screens.answer} />
				</Phone>
			)
		case 'voice':
			return (
				<Phone label={screens.voice.label} className={styles.phone}>
					<VoiceScreen {...screens.voice} />
				</Phone>
			)
		case 'tower':
			return (
				<Phone label={screens.tower.label} className={styles.phone}>
					<TowerScreen {...demo.tower} greeting="Back again" />
				</Phone>
			)
	}
}

/** How it works: the tower's three floors as a zig-zag, each beside the game's screen for it. */
export function Floors() {
	return (
		<section id="how" className={styles.section} aria-labelledby="floors-title">
			<div className="container">
				<div className={styles.head} data-reveal>
					<p className={`caption-3 ${styles.kicker}`}>{floors.kicker}</p>
					<h2 id="floors-title" className="heading-2">
						{floors.title}
					</h2>
					<p className={`body-3 ${styles.body}`}>{floors.body}</p>
				</div>
				<ol className={styles.list}>
					{floors.items.map((floor) => (
						<li key={floor.id} id={floor.id} className={`tone-${floor.tone} ${styles.row}`}>
							<div className={styles.text} data-reveal>
								<p className={`caption-3 ${styles.level}`}>
									<span className={styles.levelTag}>{floor.level}</span>
									{floor.mode}
								</p>
								<h3 className="heading-3">{floor.title}</h3>
								<p className={`body-3 ${styles.floorBody}`}>{floor.body}</p>
								<ul className={styles.points}>
									{floor.points.map((point) => (
										<li key={point} className="body-5">
											<Check weight="bold" aria-hidden="true" />
											{point}
										</li>
									))}
								</ul>
							</div>
							<div className={styles.visual} data-reveal>
								<FloorScreen floor={floor} />
							</div>
						</li>
					))}
				</ol>
			</div>
		</section>
	)
}
