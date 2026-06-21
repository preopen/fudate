import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const chrome = process.env.CHROME_BIN || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
if (!existsSync(chrome)) {
  throw new Error(`Chrome not found. Set CHROME_BIN or install Chrome: ${chrome}`);
}

const cwd = process.cwd();
const input = `file://${join(cwd, 'high-fidelity-user-flow.html')}`;
const output = join(cwd, 'high-fidelity-user-flow.png');

const result = spawnSync(chrome, [
  '--headless=new',
  '--disable-gpu',
  '--hide-scrollbars',
  '--allow-file-access-from-files',
  '--window-size=1280,17800',
  `--screenshot=${output}`,
  input
], { stdio: 'inherit' });

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}

console.log(`rendered ${output}`);
