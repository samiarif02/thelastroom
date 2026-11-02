import type { Metadata, Viewport } from 'next'
import { Bricolage_Grotesque, Geist } from 'next/font/google'
import type { ReactNode } from 'react'

import { faq, site } from '@/content/site'

import './globals.css'

// Daylight Tower's pair (docs/design/direction.md, "Type" and "The landing page"): Bricolage
// Grotesque 600 for display, Geist 400/500/600 for reading. Both SIL OFL. next/font downloads them
// at build time and serves them from this site, so a visitor's browser never calls Google.
//
// One display weight and no optical-size axis: the full opsz × wght variable file is 77 KB, the
// 600 instance 22 KB, and on a throttled phone that difference is Lighthouse's whole margin.
const display = Bricolage_Grotesque({
	subsets: ['latin'],
	weight: '600',
	variable: '--font-display',
	display: 'swap'
})

const ui = Geist({
	subsets: ['latin'],
	weight: ['400', '500', '600'],
	variable: '--font-ui',
	display: 'swap'
})

export const metadata: Metadata = {
	metadataBase: new URL(site.url),
	title: site.title,
	description: site.description,
	applicationName: site.name,
	alternates: { canonical: '/' },
	openGraph: {
		type: 'website',
		url: '/',
		siteName: site.name,
		title: site.title,
		description: site.description,
		locale: 'en_GB'
	},
	twitter: {
		card: 'summary_large_image',
		title: site.title,
		description: site.description
	},
	robots: { index: true, follow: true }
}

export const viewport: Viewport = {
	themeColor: '#fbf6ee',
	colorScheme: 'light'
}

/** The FAQ as structured data, for search and answer engines (landing-page-design A7). */
const faqSchema = {
	'@context': 'https://schema.org',
	'@type': 'FAQPage',
	mainEntity: faq.items.map((item) => ({
		'@type': 'Question',
		name: item.q,
		acceptedAnswer: { '@type': 'Answer', text: item.a }
	}))
}

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
	return (
		<html lang="en-GB" className={`${display.variable} ${ui.variable}`}>
			<body>
				<a className="skip-link" href="#main">
					Skip to content
				</a>
				{children}
				<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }} />
			</body>
		</html>
	)
}
