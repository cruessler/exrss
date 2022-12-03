const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

const elmRoot = path.resolve(__dirname, 'elm');

module.exports = () => ({
  optimization: {
    minimizer: [
      new TerserPlugin({ parallel: true }),
      new CssMinimizerPlugin({}),
    ],
  },
  entry: './js/app.js',
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js'),
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },
      {
        test: /\.scss$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/],
        loader: 'elm-webpack-loader',
        options: {
          cwd: elmRoot,
          pathToElm: '../node_modules/.bin/elm',
          optimize: process.env.NODE_ENV === 'production',
        },
      },
    ],
    noParse: [/\.elm$/],
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin({ patterns: [{ from: 'static/', to: '../' }] }),
  ],
  watchOptions: {
    aggregateTimeout: 1000,
  },
});
