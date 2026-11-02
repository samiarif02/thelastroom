import type { Metadata, Viewport } from 'next'
import { Atkinson_Hyperlegible, Overpass, Overpass_Mono } from 'next/font/google'
import type { ReactNode } from 'react'

import { site } from '@/content/site'

import './globals.css'

// "Wayfinding" type, shared with the app: Overpass (drawn from highway signage) for display, set
// heavy and tight like floor signs; Atkinson Hyperlegible for text; Overpass Mono for labels, floor
// and room numbers, and scores. All SIL OFL. next/font downloads them at build time and serves them
// from this site, so a visitor's browser never calls Google.
//
// One weight each, three small files: the page stays inside Lighthouse's mobile budget (every
// extra weight is another font in the way of the first paint on a throttled phone).
const display = Overpass({
	subsets: ['latin'],
	weight: '800',
	variable: '--font-display',
	display: 'swap'
})

const body = Atkinson_Hyperlegible({
	subsets: ['latin'],
	weight: '400',
	variable: '--font-body',
	display: 'swap'
})

const mono = Overpass_Mono({
	subsets: ['latin'],
	weight: '600',
	variable: '--font-mono',
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
	themeColor: '#0b1d22',
	colorScheme: 'dark'
}

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
	return (
		<html lang="en-GB" className={`${display.variable} ${body.variable} ${mono.variable}`}>
			<body>
				<a className="skip-link" href="#main">
					Skip to content
				</a>
				{children}
			</body>
		</html>
	)
}
