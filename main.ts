// Brainrot Lagoon — the entrypoint for make.fun's roblox-brainrot-01.
// Runs on Node 22 with the standard library only. Its whole job is to hand the
// game over to the grader: copy the built place, the sources, the screenshots
// and PLAY.json into the output directory, then write dossier.json there using
// the vendored library (vendor/makefun-roblox.ts).
//
// Build the place first:
//   node tools/gen-project.mjs && rojo build default.project.json --output game.rbxl
// Then run this the way the scorer does:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// Names under /output must start with a letter, a digit or _ and may only hold
// letters, digits, . _ and - — a dotted name such as .gitkeep or .DS_Store
// anywhere under it fails the entry, so the copies below skip dotted names.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoRoot = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Keep cpSync from carrying over any file or directory whose name starts with a dot. */
function skipDotted(path: string): boolean {
	return !basename(path).startsWith('.');
}

copyFileSync(join(repoRoot, 'game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(join(repoRoot, 'PLAY.json'), join(outputDir, 'PLAY.json'));
cpSync(join(repoRoot, 'src'), join(outputDir, 'src'), { recursive: true, filter: skipDotted });
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoRoot, 'screenshots'))) {
	cpSync(join(repoRoot, 'screenshots'), join(outputDir, 'screenshots'), { recursive: true, filter: skipDotted });
}

// The caps come from the competition's gate.json. Only text_max_bytes changes the
// dossier's bytes; the rest make this program refuse exactly where the scorer
// would (more than 4 screenshots, one over 256 KiB, a place over 500000
// instances, scripts' sources over 8 MiB in all, or their paths over 1048576
// characters in all).
writeFileSync(
	join(outputDir, 'dossier.json'),
	buildDossier(outputDir, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
