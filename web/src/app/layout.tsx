import type { Metadata, Viewport } from 'next'
import { Cormorant_Garamond, Manrope } from 'next/font/google'
import type { ReactNode } from 'react'

import { site } from '@/content/site'

import './globals.css'

// The app's pair (DESIGN.md, D4). next/font downloads them at build time and serves them from
// this site, so a visitor's browser never calls Google.
const serif = Cormorant_Garamond({
	subsets: ['latin'],
	weight: '500',
	style: ['normal', 'italic'],
	variable: '--font-serif',
	display: 'swap'
})

const sans = Manrope({
	subsets: ['latin'],
	variable: '--font-sans',
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
	themeColor: '#0a0e16',
	colorScheme: 'dark'
}

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
	return (
		<html lang="en-GB" className={`${serif.variable} ${sans.variable}`}>
			<body>
				<a className="skip-link" href="#main">
					Skip to content
				</a>
				{children}
			</body>
		</html>
	)
}
