# Frontend scaffold notes (Vite + React + TypeScript + Tailwind v4 + shadcn/ui)

Only relevant when the project needs a frontend scaffolded from scratch on
this agent's fixed hosting (S3 + the existing CloudFront distribution --
never a new distribution or bucket per project). None of this is
domain-specific; it's the same setup regardless of what the app does.

## Scaffold commands, in order

```bash
npm create vite@latest . -- --template react-ts
npm install
npm install -D tailwindcss postcss autoprefixer @tailwindcss/postcss
npm install -D @types/node
npx shadcn@latest init -d --force
```

## Known shadcn CLI gotcha: writes to a literal `@` directory

On at least one shadcn CLI version, running `npx shadcn@latest add ...` after
`vite.config.ts` defines the `@/*` path alias can write component files to a
literal directory named `@` at the project root (`./@/components/ui/...`)
instead of resolving the alias to `./src/components/ui/...`. Check for this
immediately after any `shadcn add` command:

```bash
find "@" -type f 2>/dev/null
```

If files show up there, move them and remove the stray directory:

```bash
mkdir -p src/components/ui src/lib
cp -r "@/components/ui/." src/components/ui/
cp -r "@/lib/." src/lib/
rm -rf "@"
```

## tsconfig.app.json: `baseUrl` is deprecated in newer TypeScript

`moduleResolution: "bundler"` with a `paths` map works without `baseUrl` --
omit it. Setting it triggers `TS5101` (deprecated, will stop functioning in
TypeScript 7.0):

```json
{
  "compilerOptions": {
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./src/*"] }
    // no "baseUrl": "." -- not needed with moduleResolution: bundler
  }
}
```

## vite.config.ts: use `import.meta.dirname`, not `__dirname`

Newer Vite's native config loader warns on `__dirname` (a CJS global, not
available in the ESM config context Vite now prefers):

```typescript
import path from 'node:path';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(import.meta.dirname, './src') },
  },
});
```

## Watch for a broken self-hosted font import from shadcn's theme

Some shadcn "base" themes add `@import "@fontsource-variable/geist";` to the
generated `index.css`. In at least one observed case this produced unresolved
`.woff2` asset warnings at build time and a broken font reference in the
production bundle. If `npm run build` warns about `.woff2` files "didn't
resolve at build time," remove the `@fontsource-variable/geist` import and
its `@theme inline { --font-sans: 'Geist Variable', ... }` override, and
`npm uninstall @fontsource-variable/geist`. The system font stack fallback
(`system-ui`, etc.) is fine for a demo and has zero risk of a broken build.


## Deploying the built frontend

Always `aws s3 sync ./dist s3://<hosting-bucket> --delete` -- never `aws s3
cp --recursive` (leaves stale files from the previous deploy behind).
Caching is
disabled on the fixed CloudFront distribution, so no invalidation step is
needed.
