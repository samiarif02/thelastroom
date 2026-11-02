/** How long after the load event the page's idle motion starts, so it never slows the first paint. */
export const motionDelay = 1200

/** Runs `run` once the page has loaded and settled; returns a cancel function. */
export function afterLoad(run: () => void): () => void {
	let timer = 0
	const start = () => {
		timer = window.setTimeout(run, motionDelay)
	}
	if (document.readyState === 'complete') start()
	else window.addEventListener('load', start, { once: true })
	return () => {
		window.removeEventListener('load', start)
		window.clearTimeout(timer)
	}
}
