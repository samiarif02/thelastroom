import { FloorSection } from '@/components/FloorSection'
import { Hero } from '@/components/Hero'
import { HowItWorks, TowerStill } from '@/components/HowItWorks'
import { LastRoom } from '@/components/LastRoom'
import { Privacy } from '@/components/Privacy'
import { Scoring } from '@/components/Scoring'
import { SiteFooter } from '@/components/SiteFooter'
import { SiteHeader } from '@/components/SiteHeader'
import { VoiceNote } from '@/components/VoiceNote'
import { WhyItWorks } from '@/components/WhyItWorks'
import { floors } from '@/content/site'

const [floorOne, floorTwo, floorThree] = floors

// The page is only composition: copy lives in src/content/site.ts, layout in the components.
// It reads as the building: the lobby's directory, the three floors, then the Recall Room, the
// notice board (scoring) and the house rules (privacy).
export default function Home() {
	return (
		<div id="top">
			<SiteHeader />
			<main id="main">
				<Hero />
				<FloorSection floor={floorOne} side={<TowerStill />}>
					<HowItWorks />
				</FloorSection>
				<FloorSection floor={floorTwo}>
					<VoiceNote />
				</FloorSection>
				<FloorSection floor={floorThree}>
					<LastRoom />
				</FloorSection>
				<WhyItWorks />
				<Scoring />
				<Privacy />
			</main>
			<SiteFooter />
		</div>
	)
}
