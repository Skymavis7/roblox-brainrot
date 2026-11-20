// inspect-place.mjs — dump the built game.rbxl: instance counts, every
// script, and how the src/ files match the place's scripts.
// Node, stdlib only. Run: node tools/inspect-place.mjs

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { readPlace, matchSources } from "../vendor/makefun-roblox.ts";

const CAPS = {
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};

const buf = readFileSync("game.rbxl");
const place = readPlace(new Uint8Array(buf), CAPS);

console.log("instances: " + place.instances);
for (const cls of place.classes) {
	console.log("  " + cls.name + ": " + cls.count);
}
console.log("scripts: " + place.scripts.length);
for (const script of place.scripts) {
	const bytes = script.source ? script.source.length : 0;
	console.log("  " + script.path + " (" + script.class + ", " + bytes + " bytes)");
}
if (place.notes.length > 0) {
	for (const note of place.notes) {
		console.log("note: " + note);
	}
}

// Collect every .luau file under src/, recursively.
const srcFiles = [];
function walk(dir) {
	for (const entry of readdirSync(dir)) {
		const full = join(dir, entry);
		if (statSync(full).isDirectory()) {
			walk(full);
		} else if (entry.endsWith(".luau")) {
			const bytes = readFileSync(full);
			srcFiles.push({ path: relative(".", full), bytes: new Uint8Array(bytes) });
		}
	}
}
walk("src");

const match = matchSources(place, srcFiles);
console.log("src files: " + srcFiles.length + ", matched: " + match.matched.length + ", unmatched: " + match.unmatched.length);
for (const file of match.unmatched) {
	console.log("  unmatched: " + file);
}
const coverage = (match.coverage * 100).toFixed(1);
console.log("coverage: " + coverage + "% (" + match.coveredBytes + "/" + match.scriptBytes + " bytes)");
