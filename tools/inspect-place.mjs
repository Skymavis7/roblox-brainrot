// inspect-place.mjs — dump the built game.rbxl: instance counts, script paths, src match.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { readPlace, matchSources } from '../vendor/makefun-roblox.ts';

const buf = readFileSync('game.rbxl');
const place = readPlace(buf, { max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 });
console.log('instances:', place.instances);
console.log('classes:', place.classes.map((c) => `${c.name}=${c.count}`).join(' '));
console.log('scripts:');
for (const s of place.scripts) console.log(' -', s.path, s.class, (s.source?.length ?? 0), 'bytes');

function collect(dir, out = []) {
	for (const e of readdirSync(dir, { withFileTypes: true })) {
		const p = join(dir, e.name);
		if (e.isDirectory()) collect(p, out);
		else if (e.name.endsWith('.luau')) out.push(p);
	}
	return out;
}
const files = collect('src').map((p) => ({ path: p, bytes: readFileSync(p) }));
console.log('src files:', files.length);
const match = matchSources(place, files);
console.log('matched:', match.matched.length, 'unmatched src files:', match.unmatched);
console.log('coverage:', (match.coverage * 100).toFixed(1) + '%', `(${match.coveredBytes}/${match.scriptBytes} bytes)`);
