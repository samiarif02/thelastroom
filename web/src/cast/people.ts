// The cast's colours and expressions: a port of docs/design/mockups/shared/cast.js (the source of
// truth in docs/design/direction.md, "Characters"). The values are copied, not reinterpreted, so
// the site and the app draw the same people. When packages/brand/assets/cast/cast.json lands
// (WS1), this file should read from it instead.

export type Person = 'priya' | 'marcus' | 'lena' | 'sam'

export type Expression = 'neutral' | 'listening' | 'thinking' | 'nod' | 'smile' | 'hmm' | 'talk'

export type Palette = {
	readonly skin: string
	readonly shade: string
	readonly lip: string
	readonly blush: string
	readonly hair: string
	readonly hairHi: string
	readonly brow: string
	readonly outer: string
	readonly outerShade: string
	readonly inner: string
	readonly accent: string
	readonly beard?: string
	readonly frame?: string
	readonly freckle?: string
}

/** Illustration colours: decorative fills, never text, so they carry no contrast pairs. */
export const palettes: Readonly<Record<Person, Palette>> = {
	priya: {
		skin: '#B9785A',
		shade: '#9A5D41',
		lip: '#7E3B33',
		blush: '#D9686A',
		hair: '#1F1719',
		hairHi: '#4A3A3E',
		brow: '#1F1719',
		outer: '#1E7A72',
		outerShade: '#165F59',
		inner: '#F6EDE0',
		accent: '#E2AE45'
	},
	marcus: {
		skin: '#6F4532',
		shade: '#573424',
		lip: '#B9806C',
		blush: '#B4574F',
		hair: '#1B1412',
		hairHi: '#3A2C27',
		brow: '#1B1412',
		beard: '#241A16',
		outer: '#2B3A55',
		outerShade: '#202C42',
		inner: '#DCE8F6',
		accent: '#E0A93B',
		frame: '#14181F'
	},
	lena: {
		skin: '#F1C9AA',
		shade: '#DCA986',
		lip: '#B5584B',
		blush: '#EE8D86',
		hair: '#9A4426',
		hairHi: '#C2643E',
		brow: '#7E3720',
		outer: '#D9A23A',
		outerShade: '#B9852A',
		inner: '#C28A26',
		accent: '#2C7D74',
		freckle: '#C27E5E'
	},
	sam: {
		skin: '#C99474',
		shade: '#AA7353',
		lip: '#8E4B3E',
		blush: '#D27A6E',
		hair: '#80858A',
		hairHi: '#C2C6C9',
		brow: '#5D6266',
		outer: '#2D3437',
		outerShade: '#22282A',
		inner: '#7B2E45',
		accent: '#C9A35B'
	}
}

export type EyeKind = 'open' | 'wide' | 'up' | 'happy' | 'closed' | 'lidded'
export type BrowKind = 'neutral' | 'soft' | 'raised' | 'high' | 'low'
export type MouthKind = 'neutral' | 'soft' | 'smile' | 'hmm' | 'purse' | 'talk'

export type Pose = {
	readonly eyes: EyeKind
	readonly brows: readonly [BrowKind, BrowKind]
	readonly mouth: MouthKind
	/** Head tilt in degrees, around the neck (100, 140). */
	readonly rot: number
	/** Head drop in grid units. */
	readonly dy: number
	readonly blush: number
}

/** The seven expressions (direction.md: eyes, brows, mouth, head). */
export const poses: Readonly<Record<Expression, Pose>> = {
	neutral: { eyes: 'open', brows: ['neutral', 'neutral'], mouth: 'neutral', rot: 0, dy: 0, blush: 0 },
	listening: { eyes: 'wide', brows: ['raised', 'soft'], mouth: 'soft', rot: 3.5, dy: 1.5, blush: 0 },
	thinking: { eyes: 'up', brows: ['soft', 'high'], mouth: 'purse', rot: -5, dy: 0, blush: 0 },
	nod: { eyes: 'closed', brows: ['soft', 'soft'], mouth: 'soft', rot: 1.5, dy: 4, blush: 0.25 },
	smile: { eyes: 'happy', brows: ['soft', 'soft'], mouth: 'smile', rot: 2.5, dy: 0, blush: 0.45 },
	hmm: { eyes: 'lidded', brows: ['low', 'high'], mouth: 'hmm', rot: -2.5, dy: 0, blush: 0 },
	talk: { eyes: 'open', brows: ['soft', 'neutral'], mouth: 'talk', rot: 1, dy: 0, blush: 0 }
}

/** Brow heights (outer, peak, inner), from cast.js. */
export const browShapes: Readonly<Record<BrowKind, readonly [number, number, number]>> = {
	neutral: [73.6, 70.6, 72.6],
	soft: [72.8, 69.6, 71.6],
	raised: [70.2, 66.2, 69.2],
	high: [68.6, 64.2, 67.6],
	low: [75, 73.4, 74.4]
}

/** The eyes' ink and their catch light. */
export const featureInk = '#231A1A'
export const catchLight = '#FFF8F0'
