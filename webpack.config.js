const fs = require("fs");
const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

const ROOT = __dirname;
const SOURCE = "client";

module.exports = (env, args) => {
  const mode = args.mode || "development";
  const isDev = mode === "development";

  const entries = fs
    .readdirSync(path.resolve(ROOT, SOURCE, "Page"))
    .filter(
      (name) =>
        name.endsWith(".entry.js") || (isDev && name.endsWith(".entry.dev.js"))
    )
    .map((name) => ({
      name: name.replace(/\.entry(\.dev)?\.js/, ""),
      filename: name,
    }));

  return {
    mode,

    output: {
      path: path.resolve(ROOT, "build", "assets"),
    },

    entry: entries.reduce((map, { name, filename }) => {
      map[name] = path.resolve(ROOT, SOURCE, "Page", filename);
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
            jsonErrors: isDev,
            // TODO should be used for production builds, enable when
            // Debug.todo has been removed
            optimize: false,
            files: [
              path.resolve(ROOT, SOURCE, "Page/Client.elm"),
              path.resolve(ROOT, SOURCE, "Server.elm"),
            ],
          },
        },
      ],
    },

    plugins: entries.map(
      ({ name }) =>
        new HtmlWebpackPlugin({
          filename: name + ".html",
          chunks: [name],
          template: path.resolve(ROOT, SOURCE, "Page", name + ".html"),
        })
    ),
  };
};
