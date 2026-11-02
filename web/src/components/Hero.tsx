import { hero } from '@/content/site'

import { ButtonLink } from './ButtonLink'
import { Ornament } from './Ornament'
import { PhoneFrame } from './PhoneFrame'
import styles from './Hero.module.css'

/** The opening: the title-card name, the one line, the Android preview and the two stores. */
export function Hero() {
	const [first, second] = hero.stills
	return (
		<section className={styles.hero} aria-labelledby="hero-title">
			<div className={styles.lamp} aria-hidden="true" />
			<div className={`container ${styles.grid}`}>
				<div className={styles.copy}>
					<p className={styles.eyebrow}>{hero.eyebrow}</p>
					<h1 id="hero-title" className={styles.title}>
						{hero.title}
					</h1>
					<Ornament className={styles.ornament} />
					<p className={styles.line}>{hero.line}</p>
					<p className={styles.body}>{hero.body}</p>
					<div className={styles.actions}>
						<ButtonLink href={hero.preview.href}>{hero.preview.label}</ButtonLink>
						<p className={styles.stores}>
							<span className={styles.storesLabel}>{hero.stores.label}</span>{' '}
							{hero.stores.names.map((name, i) => (
								<span key={name}>
									{i > 0 ? <span aria-hidden="true"> · </span> : null}
									<span className={styles.store}>{name}</span>
									{i < hero.stores.names.length - 1 ? <span className="visually-hidden"> and </span> : null}
								</span>
							))}
						</p>
					</div>
				</div>
				<div className={styles.stills}>
					<PhoneFrame
						still={first}
						preload
						sizes="(min-width: 60rem) 300px, (min-width: 40rem) 260px, 62vw"
						className={styles.front}
					/>
					<PhoneFrame
						still={second}
						sizes="(min-width: 60rem) 260px, 220px"
						className={styles.back}
					/>
				</div>
			</div>
		</section>
	)
}
