import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {root} from './env.mjs';

// Render one at a time so the browser renderers remain usable on a 2-core machine.
for(const name of ['remotion','revideo','hyperframes','motion-canvas','p5']){
  console.log(`\n=== ${name} ===`);
  const result=spawnSync(process.execPath,[path.join(root,`scripts/render-${name}.mjs`)],{cwd:root,stdio:'inherit',env:process.env});
  if(result.error) throw result.error;
  if(result.status!==0) process.exit(result.status ?? 1);
}
