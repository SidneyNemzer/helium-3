const fs = require('fs')
const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')

const ROOT = __dirname
const SOURCE = 'client'
const DEV_SERVER_DOMAIN = 'http://localhost:8080/'

module.exports = (env, args) => {
  const entries = fs
    .readdirSync(path.resolve(ROOT, SOURCE, 'Page'))
    .filter(name => name.endsWith('.entry.js'))

  console.log('Building Pages:')
  entries.forEach(name => {
    console.log(name, DEV_SERVER_DOMAIN + name.replace('.entry.js', '.html'))
  })
  console.log('')

  return {
    mode: args.mode || 'development',

    entry: entries.reduce((map, name) => {
      map[name] = path.resolve(ROOT, SOURCE, 'Page', name)
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
    )
  }
}
