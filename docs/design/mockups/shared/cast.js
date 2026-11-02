// The Last Room cast, drawn in plain SVG shapes (paths, ellipses, circles, one linear gradient)
// so Flutter can redraw them with CustomPainter + Path with no converter. One 200 x 200 grid for
// everyone; see docs/design/direction.md "Characters" for the spec.
//
// Usage: <div data-cast="marcus" data-expr="listening" data-style="daylight" data-bg="..."></div>
// then Cast.mount(). Styles: "daylight" (soft shading, rim light) and "paper" (flat cut paper,
// offset print shadow, grain).
(function () {
	const FEATURE = '#231A1A'
	const PEOPLE = {
		priya: {
			skin: '#B9785A', shade: '#9A5D41', lip: '#7E3B33', blush: '#D9686A',
			hair: '#1F1719', hairHi: '#4A3A3E', brow: '#1F1719',
			outer: '#1E7A72', outerShade: '#165F59', inner: '#F6EDE0', accent: '#E2AE45'
		},
		marcus: {
			skin: '#6F4532', shade: '#573424', lip: '#B9806C', blush: '#B4574F',
			hair: '#1B1412', hairHi: '#3A2C27', brow: '#1B1412', beard: '#241A16',
			outer: '#2B3A55', outerShade: '#202C42', inner: '#DCE8F6', accent: '#E0A93B', frame: '#14181F'
		},
		lena: {
			skin: '#F1C9AA', shade: '#DCA986', lip: '#B5584B', blush: '#EE8D86',
			hair: '#9A4426', hairHi: '#C2643E', brow: '#7E3720',
			outer: '#D9A23A', outerShade: '#B9852A', inner: '#C28A26', accent: '#2C7D74', freckle: '#C27E5E'
		},
		sam: {
			skin: '#C99474', shade: '#AA7353', lip: '#8E4B3E', blush: '#D27A6E',
			hair: '#80858A', hairHi: '#C2C6C9', brow: '#5D6266',
			outer: '#2D3437', outerShade: '#22282A', inner: '#7B2E45', accent: '#C9A35B'
		}
	}

	// --- Expressions: eyes, brows, mouth, head pose -------------------------------------------
	// Eyes sit at y 86 (x 84 / 116); brows near y 74; mouth near y 117.
	const EYE = {
		open: (cx) => `<path d="M${cx - 6.6} 86 Q${cx} 77.4 ${cx + 6.6} 86 Q${cx} 92.2 ${cx - 6.6} 86Z" fill="${FEATURE}"/>
			<circle cx="${cx + 1.9}" cy="84" r="1.5" fill="#FFF8F0"/>`,
		wide: (cx) => `<path d="M${cx - 6.8} 86 Q${cx} 76 ${cx + 6.8} 86 Q${cx} 93 ${cx - 6.8} 86Z" fill="${FEATURE}"/>
			<circle cx="${cx + 2}" cy="83.4" r="1.6" fill="#FFF8F0"/>`,
		up: (cx) => `<path d="M${cx - 6.2} 85 Q${cx + 0.8} 76.6 ${cx + 6.8} 84.4 Q${cx + 0.6} 90.6 ${cx - 6.2} 85Z" fill="${FEATURE}"/>
			<circle cx="${cx + 3}" cy="82.4" r="1.5" fill="#FFF8F0"/>`,
		happy: (cx) => `<path d="M${cx - 7} 87.4 Q${cx} 78.6 ${cx + 7} 87.4 Q${cx} 84.2 ${cx - 7} 87.4Z" fill="${FEATURE}"/>`,
		closed: (cx) => `<path d="M${cx - 6.5} 86 Q${cx} 90.4 ${cx + 6.5} 86" fill="none" stroke="${FEATURE}" stroke-width="2.3" stroke-linecap="round"/>`,
		lidded: (cx) => `<path d="M${cx - 6.6} 86 L${cx + 6.6} 85.4 Q${cx} 91.4 ${cx - 6.6} 86Z" fill="${FEATURE}"/>
			<path d="M${cx - 7.4} 85.2 L${cx + 7.4} 84.6" stroke="${FEATURE}" stroke-width="1.8" stroke-linecap="round"/>`
	}

	// Lid creases above each eye: they make the eyes read as adult, not cartoon.
	const crease = (p, cx, lift = 0) =>
		`<path d="M${cx - 6} ${79.6 - lift} Q${cx} ${76.2 - lift} ${cx + 6} ${79.2 - lift}" fill="none" stroke="${p.shade}" stroke-width="1.3" stroke-linecap="round" opacity=".9"/>`

	const brow = (p, side, kind) => {
		// side -1 = viewer's left (her right), +1 = viewer's right
		const cx = side < 0 ? 84 : 116
		const shapes = {
			neutral: [73.6, 70.6, 72.6],
			soft: [72.8, 69.6, 71.6],
			raised: [70.2, 66.2, 69.2],
			high: [68.6, 64.2, 67.6],
			low: [75, 73.4, 74.4],
			knit: [72.6, 72.2, 75.6]
		}
		const [outerY, peakY, innerY] = shapes[kind]
		const outerX = cx + side * 9
		const innerX = cx - side * 7.5
		return `<path d="M${innerX} ${innerY} Q${cx + side * 1.5} ${peakY} ${outerX} ${outerY}" fill="none" stroke="${p.brow}" stroke-width="3.4" stroke-linecap="round"/>`
	}

	const MOUTH = {
		neutral: (p) => `<path d="M93 117.4 Q100 119.6 107 117.4" fill="none" stroke="${p.lip}" stroke-width="2.5" stroke-linecap="round"/>`,
		soft: (p) => `<path d="M91.5 116.6 Q100 121.6 108.5 116.6" fill="none" stroke="${p.lip}" stroke-width="2.6" stroke-linecap="round"/>`,
		smile: (p) => `<path d="M89.5 115.2 Q100 116.4 110.5 115.2 Q108.6 124.6 100 125 Q91.4 124.6 89.5 115.2Z" fill="${p.lip}"/>
			<path d="M91.6 115.6 Q100 116.6 108.4 115.6 L107.6 118.2 Q100 119.4 92.4 118.2Z" fill="#FFFBF5"/>`,
		hmm: (p) => `<path d="M93 118.6 Q99 117.2 107.6 115.8" fill="none" stroke="${p.lip}" stroke-width="2.5" stroke-linecap="round"/>`,
		purse: (p) => `<ellipse cx="103.5" cy="117.6" rx="3" ry="2.3" fill="${p.lip}"/>`,
		talk: (p) => `<path d="M94 116 Q100 115 106 116 Q105 122.6 100 122.8 Q95 122.6 94 116Z" fill="${p.lip}"/>`
	}

	const EXPR = {
		neutral: { eyes: 'open', brows: ['neutral', 'neutral'], mouth: 'neutral', rot: 0, dy: 0, blush: 0 },
		listening: { eyes: 'wide', brows: ['raised', 'soft'], mouth: 'soft', rot: 3.5, dy: 1.5, blush: 0 },
		thinking: { eyes: 'up', brows: ['soft', 'high'], mouth: 'purse', rot: -5, dy: 0, blush: 0 },
		nod: { eyes: 'closed', brows: ['soft', 'soft'], mouth: 'soft', rot: 1.5, dy: 4, blush: 0.25 },
		smile: { eyes: 'happy', brows: ['soft', 'soft'], mouth: 'smile', rot: 2.5, dy: 0, blush: 0.45 },
		hmm: { eyes: 'lidded', brows: ['low', 'high'], mouth: 'hmm', rot: -2.5, dy: 0, blush: 0 },
		talk: { eyes: 'open', brows: ['soft', 'neutral'], mouth: 'talk', rot: 1, dy: 0, blush: 0 }
	}

	// --- Shared body -----------------------------------------------------------------------------
	const HEAD = 'M100 38 C126 38 140 56 140 82 C140 106 130 125 113 132.6 C106 135.6 94 135.6 87 132.6 C70 125 60 106 60 82 C60 56 74 38 100 38Z'
	const TORSO = 'M14 200 C16 172 30 157 58 150.5 L84 145 L116 145 L142 150.5 C170 157 184 172 186 200Z'

	const face = (p, e, style) => {
		const lift = e.brows.includes('high') || e.brows.includes('raised') ? 1.2 : 0
		const shading =
			style === 'daylight'
				? `<path d="M128 56 C138 70 141 92 134 110 C128 124 118 131 108 134 C122 122 131 104 131 86 C131 74 130 64 128 56Z" fill="${p.shade}" opacity=".55"/>`
				: ''
		return `
			${shading}
			<ellipse cx="84" cy="103" rx="7.5" ry="4.2" fill="${p.blush}" opacity="${e.blush}"/>
			<ellipse cx="116" cy="103" rx="7.5" ry="4.2" fill="${p.blush}" opacity="${e.blush}"/>
			${crease(p, 84, lift)}${crease(p, 116, lift)}
			${EYE[e.eyes](84)}${EYE[e.eyes](116)}
			${brow(p, -1, e.brows[0])}${brow(p, 1, e.brows[1])}
			<path d="M99.2 90 Q96.6 100 96.4 104.2" fill="none" stroke="${p.shade}" stroke-width="2.2" stroke-linecap="round"/>
			<path d="M95.6 105.6 Q100 108.2 104.6 105.6" fill="none" stroke="${p.shade}" stroke-width="2.2" stroke-linecap="round"/>
			${MOUTH[e.mouth](p)}`
	}

	// --- People ----------------------------------------------------------------------------------
	const DRAW = {
		priya: {
			back: (p) => `<path d="M56 84 C54 52 72 31 100 31 C130 31 147 52 145 84 C144 104 146 120 151 132 C141 140 127 140 118 134 L82 134 C73 140 59 140 49 132 C54 120 56 104 56 84Z" fill="${p.hair}"/>`,
			clothes: (p) => `<path d="M84 146 L100 178 L116 146Z" fill="${p.inner}"/>
				<path d="M80 146 L100 184 L93 200 L70 200 L64 152Z" fill="${p.outerShade}"/>
				<path d="M120 146 L100 184 L107 200 L130 200 L136 152Z" fill="${p.outerShade}"/>
				<path d="M100 184 L93 200 L107 200Z" fill="${p.outer}"/>`,
			front: (p) => `<path d="M59 88 C56 58 72 39 101 39 C125 39 141 54 141.5 80 C134 64 121 54 106 51.5 C95 63 77 74 59 88Z" fill="${p.hair}"/>
				<path d="M59.5 82 C58.5 102 61 118 66.5 128 L57 130 C54 112 55 96 59.5 82Z" fill="${p.hair}"/>
				<path d="M74 50 C84 43.5 97 41.6 110 43.4 C98 44 86 47 76 53Z" fill="${p.hairHi}" opacity=".55"/>
				<circle cx="140.5" cy="104" r="4.6" fill="none" stroke="${p.accent}" stroke-width="2"/>`,
			ears: true
		},
		marcus: {
			back: () => '',
			clothes: (p) => `<path d="M84 146 L100 174 L116 146Z" fill="${p.inner}"/>
				<path d="M95.4 147.5 L104.6 147.5 L103.2 155 L96.8 155Z" fill="${p.accent}"/>
				<path d="M96.6 155 L103.4 155 L106 184 L100 193 L94 184Z" fill="${p.accent}"/>
				<path d="M81 146 L98 182 L91 200 L68 200 L63 152Z" fill="${p.outerShade}"/>
				<path d="M119 146 L102 182 L109 200 L132 200 L137 152Z" fill="${p.outerShade}"/>`,
			front: (p) => `<path d="M60.5 84 C58 54 76 38.5 100 38.5 C124 38.5 142 54 139.5 84 C137 70 131 58.5 119 53 C107 48.6 93 48.6 81 53 C69 58.5 63 70 60.5 84Z" fill="${p.hair}"/>
				<path d="M63 97 C64.5 115 77 131.5 100 135.5 C123 131.5 135.5 115 137 97 C134 107 128.5 114 121 117.5 C115 112 107 110.5 100 111.5 C93 110.5 85 112 79 117.5 C71.5 114 66 107 63 97Z" fill="${p.beard}"/>
				<path d="M88.5 112.6 Q100 106.4 111.5 112.6 Q100 110.2 88.5 112.6Z" fill="${p.beard}"/>
				<g fill="#FFFFFF" fill-opacity=".06" stroke="${p.frame}" stroke-width="2.3">
					<rect x="73.5" y="78.5" width="21" height="15.5" rx="5.5"/>
					<rect x="105.5" y="78.5" width="21" height="15.5" rx="5.5"/>
				</g>
				<path d="M94.5 84 Q100 81 105.5 84 M73.5 83.5 L61 82 M126.5 83.5 L139 82" fill="none" stroke="${p.frame}" stroke-width="2.3" stroke-linecap="round"/>
				<path d="M108.5 81.6 L112 80.6" stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity=".55"/>`,
			ears: true
		},
		lena: {
			back: (p) => `<circle cx="100" cy="31" r="15.5" fill="${p.hair}"/>
				<path d="M89 25 Q100 17 111 25 Q100 21.5 89 25Z" fill="${p.hairHi}" opacity=".6"/>`,
			clothes: (p) => `<path d="M80 146 Q100 160 120 146" fill="none" stroke="${p.inner}" stroke-width="7" stroke-linecap="round"/>
				<path d="M62 156 L70 200 M138 156 L130 200" stroke="${p.outerShade}" stroke-width="2.4" stroke-linecap="round" opacity=".7"/>
				<path d="M88 152 L100 196" stroke="${p.accent}" stroke-width="3" stroke-linecap="round"/>
				<rect x="94" y="181" width="16" height="12" rx="2.5" fill="#F7F3EA" transform="rotate(-14 102 187)"/>`,
			front: (p) => `<path d="M60 84 C57.5 55 76 37.5 100 37.5 C124 37.5 142.5 55 140 84 C138 70 132 59 122 53.5 C112 49.5 104 51 100 55.5 C96 51 88 49.5 78 53.5 C68 59 62 70 60 84Z" fill="${p.hair}"/>
				<path d="M100 55.5 C96 51 88 49.6 79 53.2 C88 51.8 95 53 100 55.5Z" fill="${p.hairHi}" opacity=".5"/>
				<path d="M62.6 80 C60 94 62 106 66.6 115" fill="none" stroke="${p.hair}" stroke-width="2.6" stroke-linecap="round"/>
				<g fill="${p.freckle}"><circle cx="79" cy="99" r="1.1"/><circle cx="84.5" cy="101.5" r="1"/><circle cx="76" cy="102.5" r="1"/><circle cx="121" cy="99" r="1.1"/><circle cx="115.5" cy="101.5" r="1"/><circle cx="124" cy="102.5" r="1"/></g>
				<circle cx="59.8" cy="97" r="1.8" fill="#E2B04B"/><circle cx="140.2" cy="97" r="1.8" fill="#E2B04B"/>`,
			ears: true
		},
		sam: {
			back: () => '',
			clothes: (p) => `<path d="M82 132 L118 132 L121 154 Q100 161 79 154Z" fill="${p.inner}"/>
				<path d="M84 140 Q100 145 116 140 M83 147 Q100 152 117 147" fill="none" stroke="#5E2034" stroke-width="1.4" opacity=".7"/>
				<path d="M79 152 L94 200 L68 200 L62 154Z" fill="${p.outerShade}"/>
				<path d="M121 152 L106 200 L132 200 L138 154Z" fill="${p.outerShade}"/>`,
			front: (p) => `<path d="M60.5 86 C56 54 74 34 102 34 C128 34 145 50 139.5 84 C137 69 129 56 117 51 C106 47 94 47.5 85 51 C73 56 64 68 60.5 86Z" fill="${p.hair}"/>
				<path d="M70 52 C80 36 104 29 126 38 C134 41 138 47 140 54 C130 44 114 40 98 42 C88 43.5 79 47 70 52Z" fill="${p.hair}"/>
				<path d="M76 47.5 C88 39 106 36.5 122 41 M84 52 C96 46.5 110 45.5 124 48.5" fill="none" stroke="${p.hairHi}" stroke-width="1.7" stroke-linecap="round" opacity=".6"/>
				<path d="M126 89 L130.5 87.5 M126.2 92.4 L130.6 92.6" stroke="${p.shade}" stroke-width="1.1" stroke-linecap="round"/>
				<path d="M74 89 L69.5 87.5 M73.8 92.4 L69.4 92.6" stroke="${p.shade}" stroke-width="1.1" stroke-linecap="round"/>
				<path d="M88.6 108 Q86.6 113 88.4 117.6 M111.4 108 Q113.4 113 111.6 117.6" fill="none" stroke="${p.shade}" stroke-width="1.2" stroke-linecap="round" opacity=".8"/>
				<circle cx="140.4" cy="99" r="1.6" fill="${p.accent}"/>`,
			ears: true
		}
	}

	let uid = 0
	function svg(name, exprName = 'neutral', style = 'daylight', opts = {}) {
		const p = PEOPLE[name]
		const d = DRAW[name]
		const e = EXPR[exprName] || EXPR.neutral
		const id = `c${++uid}`
		const sunlit = style === 'daylight'
		const torsoFill = p.outer
		const headT = `translate(0 ${e.dy}) rotate(${e.rot} 100 140)`
		const neck = `<path d="M85 118 L115 118 L117 150 L83 150Z" fill="${p.shade}"/>
			<path d="M85 122 Q100 136 115 122 L115 132 Q100 142 85 132Z" fill="#000" opacity=".12"/>`
		const ears = `<ellipse cx="60.5" cy="90" rx="6" ry="9.5" fill="${p.shade}"/><ellipse cx="139.5" cy="90" rx="6" ry="9.5" fill="${p.shade}"/>
			<ellipse cx="61.5" cy="90" rx="3" ry="5.5" fill="${p.skin}" opacity=".5"/><ellipse cx="138.5" cy="90" rx="3" ry="5.5" fill="${p.skin}" opacity=".5"/>`
		const rim = sunlit
			? `<path d="M64 72 C66 56 77 44.5 91 41" fill="none" stroke="#FFF6E2" stroke-width="2" stroke-linecap="round" opacity=".35"/>
				`
			: ''
		const body = `
			<g transform="${headT}">${d.back(p)}</g>
			${neck}
			<path d="${TORSO}" fill="${torsoFill}"/>
			${d.clothes(p)}
			${rim.split('\n')[1] || ''}
			<g transform="${headT}">
				${ears}
				<path d="${HEAD}" fill="${p.skin}"/>
				${face(p, e, style)}
				${d.front(p)}
				${sunlit ? rim.split('\n')[0] : ''}
			</g>`
		const defs = `<defs>
			<filter id="${id}g" x="0" y="0" width="100%" height="100%">
				<feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="4"/>
				<feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 .22 0"/>
				<feComposite in2="SourceGraphic" operator="in"/>
			</filter>
		</defs>`
		const bg = opts.bg ? `<rect width="200" height="200" fill="${opts.bg}"/>` : ''
		const paperShadow = !sunlit && opts.shadow
			? `<g transform="translate(7 5)" opacity="1"><g fill="${opts.shadow}">
					<path d="${TORSO}"/><g transform="${headT}"><path d="${HEAD}"/>${name === 'lena' ? '<circle cx="100" cy="31" r="15.5"/>' : ''}${name === 'priya' ? '<path d="M56 84 C54 52 72 31 100 31 C130 31 147 52 145 84 C144 104 146 120 151 132 C141 140 127 140 118 134 L82 134 C73 140 59 140 49 132 C54 120 56 104 56 84Z"/>' : ''}</g>
				</g></g>`
			: ''
		const grain = !sunlit ? `<g filter="url(#${id}g)">${body}</g>` : ''
		const vb = opts.viewBox || '0 0 200 200'
		return `<svg viewBox="${vb}" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="${opts.par || 'xMidYMax meet'}" aria-label="${name}, ${exprName}">${defs}${bg}${paperShadow}<g>${body}</g>${grain}</svg>`
	}

	function mount(root = document) {
		root.querySelectorAll('[data-cast]').forEach((el) => {
			el.innerHTML = svg(el.dataset.cast, el.dataset.expr, el.dataset.style || 'daylight', {
				bg: el.dataset.bg,
				shadow: el.dataset.shadow,
				viewBox: el.dataset.viewbox,
				par: el.dataset.par
			})
		})
	}

	window.Cast = { svg, mount, PEOPLE, EXPRESSIONS: Object.keys(EXPR) }
})()
