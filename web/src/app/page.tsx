import { Hero } from '@/components/Hero'
import { HowItWorks } from '@/components/HowItWorks'
import { Privacy } from '@/components/Privacy'
import { Scoring } from '@/components/Scoring'
import { SiteFooter } from '@/components/SiteFooter'
import { SiteHeader } from '@/components/SiteHeader'
import { WhyItWorks } from '@/components/WhyItWorks'

// The page is only composition: copy lives in src/content/site.ts, layout in the components.
export default function Home() {
	return (
		<div id="top">
			<SiteHeader />
			<main id="main">
				<Hero />
				<HowItWorks />
				<WhyItWorks />
				<Scoring />
				<Privacy />
			</main>
			<SiteFooter />
		</div>
	)
}
