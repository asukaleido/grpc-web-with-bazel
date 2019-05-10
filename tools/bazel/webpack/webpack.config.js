/* eslint-disable no-console, no-undef */

const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');

const DEBUG = true;

const ROOT_PATH = 'TMPL_ROOT_PATH';
const NODE_MODULES_ROOTS = TMPL_NODE_MODULES_ROOTS;
const WEBPACK_NODE_MODULES_ROOT = 'TMPL_WEBPACK_NODE_MODULES_ROOT';

if (DEBUG) {
  const fs = require('fs');
  const directories = fs.readdirSync(process.cwd());
  console.error(`
Webpack: running with
  cwd: ${process.cwd()}
  directories directly under cwd: ${directories.join(', ')}
  ROOT_PATH: ${ROOT_PATH}
  NODE_MODULES_ROOTS: ${NODE_MODULES_ROOTS.join(', ')}
  WEBPACK_NODE_MODULES_ROOT: ${WEBPACK_NODE_MODULES_ROOT}
`);
}

module.exports = {
  mode: 'none',

  target: 'web',

  resolve: {
    modules: [
      'node_modules',
      ...NODE_MODULES_ROOTS.map((root) => path.resolve(process.cwd(), root)),
    ],
  },

  output: {
    filename: '[name]-[chunkhash].js',
    chunkFilename: '[name]-[chunkhash].bundle.js',
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        use: {
          loader: path.resolve(process.cwd(), `${WEBPACK_NODE_MODULES_ROOT}/babel-loader`),
          options: {
            presets: [
              path.resolve(process.cwd(), `${WEBPACK_NODE_MODULES_ROOT}/@babel/preset-env`),
            ],
            plugins: [
              [
                path.resolve(
                  process.cwd(),
                  `${WEBPACK_NODE_MODULES_ROOT}/babel-plugin-module-resolver`,
                ),
                {
                  alias: {
                    '^@grpc-web-with-bazel/(.+)': ([, name]) =>
                      path.resolve(process.cwd(), `${ROOT_PATH}/packages/${name}`),
                  },
                },
              ],
            ],
          },
        },
      },
    ],
  },

  plugins: [new ManifestPlugin()],

  optimization: {
    minimize: true,
    minimizer: [new TerserPlugin({})],
    splitChunks: {
      cacheGroups: {
        vendor: {
          test: /node_modules/,
          name: 'vendor',
          chunks: 'initial',
          enforce: true,
        },
      },
    },
  },

  stats: {
    entrypoints: false,
  },
};
