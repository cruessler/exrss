// This file was initially created using content from
// https://www.phoenixdiff.org/compare/1.6.15...1.7.0

const plugin = require('tailwindcss/plugin');

module.exports = {
  content: [
    './elm/**/*.elm',
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex',
  ],
  theme: {
    extend: {
      colors: {
        brand: '#FD4F00',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', [
        '.phx-no-feedback&',
        '.phx-no-feedback &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ]),
    ),
  ],
};
