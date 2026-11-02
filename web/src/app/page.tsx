import { Faq } from '@/components/Faq'
import { Finale } from '@/components/Finale'
import { Floors } from '@/components/Floors'
import { Hero } from '@/components/Hero'
import { PageMotion } from '@/components/PageMotion'
import { Panel } from '@/components/Panel'
import { Scoring } from '@/components/Scoring'
import { SiteFooter } from '@/components/SiteFooter'
import { SiteNav } from '@/components/SiteNav'
import { Tagline } from '@/components/Tagline'

// The page is only composition: copy lives in src/content/site.ts, layout in the components.
// Layout type A (landing-page-design A3): a classic hero, then the argument (the tagline, the
// panel, the floors, the score and its proof), then the objections (FAQ) and the same call to
// action again.
export default function Home() {
	return (
		<div id="top">
			<SiteNav />
			<main id="main">
				<Hero />
				<Tagline />
				<Panel />
				<Floors />
				<Scoring />
				<Faq />
				<Finale />
			</main>
			<SiteFooter />
			<PageMotion />
		</div>
	)
}
