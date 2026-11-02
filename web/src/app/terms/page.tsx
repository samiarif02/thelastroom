import type { Metadata } from 'next'

import { LegalPage } from '@/components/LegalPage'
import { site, terms } from '@/content/site'

export const metadata: Metadata = {
	title: `${terms.title} · ${site.name}`,
	description: terms.description,
	alternates: { canonical: '/terms/' }
}

export default function Terms() {
	return <LegalPage {...terms} />
}
