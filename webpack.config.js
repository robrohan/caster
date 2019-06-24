// const DEBUG = (process.env.NODE_ENV !== 'production'
//                 && process.env.NODE_ENV !== 'test');

// const webpack = require('webpack');
const path = require('path');

const config = {
  mode: 'production',
  entry: {
    caster: './src/main.js',
  },
  resolve: {
    extensions: ['.js'],
  },
  output: {
    path: path.join(__dirname, 'dist'),
    filename: '[name].js',
    chunkFilename: '[id].js',
    libraryTarget: 'umd',
    globalObject: 'this',
  },
  plugins: [],
  module: {
    rules: [
      {
        test: /\.js$/,
        loader: 'babel-loader',
      },
      {
        test: /\.css$/,
        loader: 'style!css',
      },
      {
        test: /\.css$/,
        loader: 'css-loader!postcss-loader',
      },
      {
        test: /\.(png|jpg|gif|svg)$/,
        loader: 'file-loader?name=img/img-[hash:6].[ext]',
      },
      {
        test: /\.html$/,
        loader: 'html-loader',
      },
      {
        test: /\.glsl$/,
        loader: 'raw-loader',
      },
      {
        test: /\.worker\.js$/,
        use: {
          loader: 'worker-loader',
          options: {inline: true},
        },
      },
    ],
  },
};

module.exports = config;
