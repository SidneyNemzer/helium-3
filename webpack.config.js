const fs = require('fs')
const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

const ROOT = __dirname
const DEV_SERVER_DOMAIN = 'http://localhost:8080/'

module.exports = (env, args) => {
  const IS_DEV = args.mode === 'development' || args.$0.includes('webpack-dev-server')
  const entries = fs
    .readdirSync(path.resolve(ROOT, './src/Page'))
    .filter(name => name.endsWith('.entry.js'))

  console.log('Pages:')
  entries.forEach(name => {
    console.log(DEV_SERVER_DOMAIN + name.replace('.entry.js', '.html'), `(${name})`)
  })
  console.log('')

  return {
    mode: args.mode || 'development',

    devServer: {
      contentBase: path.resolve(ROOT, './src/public')
    },

    entry: entries.reduce((map, name) => {
      map[name] = path.resolve(ROOT, './src/Page/', name)
      return map
    }, {}),

    module: {
      strictExportPresence: true,
      noParse: /\.elm$/,
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader: 'elm-webpack-loader',
          options: { cwd: ROOT }
        }
      ]
    },

    plugins: entries.map(name =>
      new HtmlWebpackPlugin({
        title: 'Helium 3',
        filename: name.replace('.entry.js', '.html'),
        inject: true,
        chunks: [ name ]
      })
    ).concat([
      new CopyWebpackPlugin([ 'public' ])
    ])
  }
}
