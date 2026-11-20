// main.ts — entrypoint for Brainrot Lagoon (make.fun roblox-brainrot-01).
// Copies the built place, the sources, the screenshots and PLAY.json into the
// output directory, then writes dossier.json there with the vendored library.
//
// What the dossier holds (makefun/dossier/v1): a `cover` summary of the
// place (instance counts, top classes, script list), the `text` of every
// counted source file joined in one capped blob, and the `images` (the
// screenshots, base64). The output directory mirrors the entry layout:
// game.rbxl, PLAY.json, src/ (the 15 Luau sources), screenshots/ (up to 4),
// and dossier.json itself. Nothing dotted is copied: a dotted name under
// /output fails the entry, so copyTree skips dot-prefixed entries.
//
// Build first:
//   node tools/gen-project.mjs && rojo build default.project.json --output game.rbxl
// Run:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const outDir = process.env.MAKEFUN_OUTPUT_DIR || "/output";
mkdirSync(outDir, { recursive: true });

const dotted = (name: string) => name.startsWith(".");

// Copy game.rbxl and PLAY.json.
for (const file of ["game.rbxl", "PLAY.json"]) {
	if (existsSync(file)) {
		cpSync(file, join(outDir, file));
	}
}

// Copy a directory tree recursively, skipping dotted names.
function copyTree(src: string, dest: string): void {
	mkdirSync(dest, { recursive: true });
	for (const entry of readdirSync(src)) {
		if (dotted(entry)) {
			continue;
		}
		const from = join(src, entry);
		const to = join(dest, entry);
		if (statSync(from).isDirectory()) {
			copyTree(from, to);
		} else {
			cpSync(from, to);
		}
	}
}

// Copy src/ and screenshots/ (when present).
copyTree("src", join(outDir, "src"));
if (existsSync("screenshots")) {
	copyTree("screenshots", join(outDir, "screenshots"));
}

const dossier = buildDossier(outDir, {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, "dossier.json"), dossier);
console.log("wrote " + join(outDir, "dossier.json") + " (" + dossier.length + " bytes)");
