import type { NextConfig } from 'next'

// A static export: `next build` writes plain HTML, CSS and images to `out/`. No server, no
// secrets, no environment variables (brief 34, ADR 0007).
const nextConfig: NextConfig = {
	output: 'export',
	// The image optimiser needs a server; the stills are already sized and compressed.
	images: { unoptimized: true },
	// Every route is a folder with an index.html, which every static host serves as is.
	trailingSlash: true,
	poweredByHeader: false,
	reactStrictMode: true
}

export default nextConfig
