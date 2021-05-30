const fs = require("fs");
const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

const ROOT = __dirname;
const SOURCE = "client";

module.exports = (env, args) => {
  const entries = fs
    .readdirSync(path.resolve(ROOT, SOURCE, "Page"))
    .filter((name) => name.endsWith(".entry.js"))
    .map((name) => name.replace(".entry.js", ""));

  return {
    mode: args.mode || "development",

    entry: entries.reduce((map, name) => {
      map[name] = path.resolve(ROOT, SOURCE, "Page", name + ".entry.js");
      return map;
    }, {}),

    module: {
      strictExportPresence: true,
      noParse: /\.elm$/,
      rules: [
        {
          // TODO the elm compiler runs twice because two different files
          // import elm modules
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader: require.resolve("./scripts/lib/elm-webpack-loader"),
          options: {
            cwd: ROOT,
            debug: false,
            files: [
              path.resolve(ROOT, SOURCE, "Page/Client.elm"),
              path.resolve(ROOT, SOURCE, "Server.elm"),
            ],
          },
        },
      ],
    },

    plugins: entries.map(
      (name) =>
        new HtmlWebpackPlugin({
          filename: name + ".html",
          chunks: [name],
          template: path.resolve(ROOT, SOURCE, "Page", name + ".html"),
        })
    ),
  };
};
