import esbuild from 'esbuild';
import ElmPlugin from 'esbuild-plugin-elm';

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
];

let opts = {
  entryPoints: ['js/app.js'],
  bundle: true,
  target: 'es2017',
  outdir: '../priv/static/assets',
  logLevel: 'info',
  plugins,
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: 'inline',
  };
  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_error) => {
      process.exit(1);
    });
} else {
  esbuild.build(opts);
}
