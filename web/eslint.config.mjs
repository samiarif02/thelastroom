import { defineConfig, globalIgnores } from 'eslint/config'
import nextVitals from 'eslint-config-next/core-web-vitals'
import nextTs from 'eslint-config-next/typescript'

// Next's own rules (React, hooks, accessibility, Core Web Vitals, TypeScript), plus the two
// 8x rules the template writes out: no `any`, no console. `npm run lint` adds --max-warnings=0.
export default defineConfig([
	...nextVitals,
	...nextTs,
	{
		rules: {
			'@typescript-eslint/no-explicit-any': 'error',
			'no-console': 'error'
		}
	},
	globalIgnores(['.next/**', 'out/**', 'next-env.d.ts'])
])
