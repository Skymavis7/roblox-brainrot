// tools/inspect-place.mjs — dumps the built game.rbxl: instance count, class
// counts, every script, and how the src/ files match the place's scripts.
// Node, stdlib only. Run from the repo root:  node tools/inspect-place.mjs
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { readPlace, matchSources } from "../vendor/makefun-roblox.ts";

const raw = new Uint8Array(readFileSync("game.rbxl"));
const place = readPlace(raw, {
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});

console.log(`Instances: ${place.instances}`);
console.log("Classes (most instances first):");
for (const cls of place.classes) console.log(`  ${cls.name}: ${cls.count}`);
console.log(`Scripts: ${place.scripts.length}`);
for (const script of place.scripts) {
  const bytes = script.source === null ? 0 : script.source.length;
  console.log(`  ${script.path} [${script.class}] ${bytes} bytes`);
}
for (const note of place.notes) console.log(`Note: ${note}`);

// Every .luau file under src/, recursively.
const files = [];
function walk(dir, rel) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) continue;
    const path = join(dir, entry.name);
    const relPath = rel ? `${rel}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      walk(path, relPath);
    } else if (entry.name.endsWith(".luau")) {
      files.push({ path: relPath, bytes: new Uint8Array(readFileSync(path)) });
    }
  }
}
walk("src", "");

const match = matchSources(place, files);
console.log(`src/ files: ${files.length}, matched: ${match.matched.length}, unmatched: ${match.unmatched.length}`);
for (const name of match.unmatched) console.log(`  UNMATCHED src file: ${name}`);
place.scripts.forEach((script, i) => {
  if (!match.scriptMatched[i]) console.log(`  UNMATCHED place script: ${script.path}`);
});
console.log(
  `Coverage: ${(match.coverage * 100).toFixed(1)}% (${match.coveredBytes}/${match.scriptBytes} bytes)`
);
