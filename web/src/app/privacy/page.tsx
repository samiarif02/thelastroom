import type { Metadata } from 'next'

import { LegalPage } from '@/components/LegalPage'
import { privacy, site } from '@/content/site'

export const metadata: Metadata = {
	title: `${privacy.title} · ${site.name}`,
	description: privacy.description,
	alternates: { canonical: '/privacy/' }
}

export default function Privacy() {
	return <LegalPage {...privacy} />
}
