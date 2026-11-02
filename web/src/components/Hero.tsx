import { floors, hero, rooms } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { SignArrow } from './SignArrow'
import { StoresLine } from './StoresLine'
import styles from './Hero.module.css'

const [lastFloor] = floors.slice(-1)

/**
 * The lobby: the line, the Android preview, the stores, and the building's directory board, which
 * lists the real structure (21 rooms on three floors, the last room at the top) and links to each.
 */
export function Hero() {
	const { directory } = hero
	return (
		<section className={styles.lobby} aria-labelledby="hero-title" data-lift="L" data-lift-name="Lobby">
			<div className={`container ${styles.grid}`}>
				<div className={styles.copy}>
					<p className={`label ${styles.kicker}`}>{hero.kicker}</p>
					<h1 id="hero-title" className={styles.title}>
						{hero.title}
					</h1>
					<p className={styles.body}>{hero.body}</p>
					<div className={styles.actions}>
						<ButtonLink href={hero.preview.href}>{hero.preview.label}</ButtonLink>
						<StoresLine />
					</div>
				</div>
				<nav className={styles.board} aria-label="Directory: the three floors">
					<p className={`label ${styles.boardHead}`}>
						<span>{directory.building}</span>
						<span>{directory.title}</span>
					</p>
					<ol className={styles.rows}>
						<li>
							<a href={`#${lastFloor?.id ?? ''}`} className={styles.row} data-tone="oxblood">
								<span className={`${styles.mark} ${styles.top}`}>{directory.lastRoom.mark}</span>
								<span className={styles.name}>{directory.lastRoom.name}</span>
								<span className={`label ${styles.detail}`}>{directory.lastRoom.detail}</span>
								<SignArrow direction="up" className={styles.arrow} />
							</a>
						</li>
						{[...floors].reverse().map((floor) => (
							<li key={floor.id}>
								<a href={`#${floor.id}`} className={styles.row} data-tone={floor.tone}>
									<span className={styles.mark}>{floor.level}</span>
									<span className={styles.name}>{floor.title}</span>
									<span className={`label ${styles.detail}`}>{`${rooms.span(floor)} · ${floor.mode}`}</span>
									<SignArrow direction="up" className={styles.arrow} />
								</a>
							</li>
						))}
						<li className={`${styles.row} ${styles.here}`} data-tone="neutral">
							<span className={`${styles.mark} ${styles.lobbyMark}`}>{directory.lobby.mark}</span>
							<span className={styles.name}>{directory.lobby.name}</span>
							<span className={`label ${styles.detail}`}>{directory.lobby.detail}</span>
						</li>
					</ol>
					<p className={`label ${styles.boardFoot}`}>{directory.summary}</p>
				</nav>
			</div>
		</section>
	)
}
