// 2023-04-07
//
// This file does not work with esbuild > 0.16 as esbuild’s API has changed in
// 0.17.
//
// esbuild-sass-plugin is pinned to version < 2.6 because versions > 2.5 require
// esbuild 0.17.
//
// https://github.com/evanw/esbuild/blob/main/CHANGELOG.md#0170

import esbuild from 'esbuild';
import ElmPlugin from 'esbuild-plugin-elm';
import { sassPlugin } from 'esbuild-sass-plugin';

const args = process.argv.slice(2);
const watch = args.includes('--watch');
const deploy = args.includes('--deploy');

const plugins = [
  ElmPlugin({
    cwd: './elm/',
    debug: !deploy,
    optimize: deploy,
    clearOnWatch: watch,
  }),
  sassPlugin(),
];

let opts = {
  entryPoints: ['js/app.js'],
  bundle: true,
  target: 'es2017',
  outdir: '../priv/static/assets',
  logLevel: 'info',
  plugins,
};

if (watch) {
  opts = {
    ...opts,
    watch,
    sourcemap: 'inline',
  };
}

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

const promise = esbuild.build(opts);

if (watch) {
  promise.then((_result) => {
    process.stdin.on('close', () => {
      process.exit(0);
    });

    process.stdin.resume();
  });
}
