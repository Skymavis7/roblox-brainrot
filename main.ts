// Brainrot Lagoon — make.fun entrypoint (Node 22, stdlib only).
// Copies the built place, the Luau sources, the screenshots and PLAY.json
// into the output directory, then writes dossier.json with the vendored
// makefun-roblox library. Run from the repo root after building:
//   node tools/gen-project.mjs && rojo build default.project.json --output game.rbxl
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";
const root = process.cwd();

function isHidden(name: string): boolean {
  return name.startsWith(".");
}

// Copy one file or directory, skipping anything whose name starts with a dot
// (a dotted name under /output fails the entry).
function copyInto(source: string, target: string): void {
  const info = statSync(source);
  if (info.isDirectory()) {
    mkdirSync(target, { recursive: true });
    for (const entry of readdirSync(source)) {
      if (isHidden(entry)) continue;
      copyInto(join(source, entry), join(target, entry));
    }
    return;
  }
  cpSync(source, target);
}

function mustExist(path: string): void {
  if (!existsSync(path)) {
    throw new Error(`main.ts: missing required file ${path} — build first`);
  }
}

mkdirSync(outDir, { recursive: true });

mustExist(join(root, "game.rbxl"));
mustExist(join(root, "PLAY.json"));
mustExist(join(root, "src"));

copyInto(join(root, "game.rbxl"), join(outDir, "game.rbxl"));
copyInto(join(root, "PLAY.json"), join(outDir, "PLAY.json"));
copyInto(join(root, "src"), join(outDir, "src"));

const shots = join(root, "screenshots");
if (existsSync(shots)) {
  copyInto(shots, join(outDir, "screenshots"));
}

const dossier = buildDossier(outDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});

writeFileSync(join(outDir, "dossier.json"), dossier);
console.log(`dossier.json written: ${dossier.length} bytes`);
