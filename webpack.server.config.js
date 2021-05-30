const path = require("path");

const ROOT = __dirname;
const SOURCE = "client";

module.exports = (env, args) => ({
  mode: args.mode || "development",

  entry: path.resolve(ROOT, SOURCE, "Server.entry.js"),

  output: {
    path: path.resolve(ROOT, "server"),
    libraryTarget: "module",
    filename: "Server.js",
  },

  experiments: {
    outputModule: true,
  },

  module: {
    strictExportPresence: true,
    noParse: /\.elm$/,
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: require.resolve("./scripts/lib/elm-webpack-loader"),
        options: {
          // TODO should be used for production builds, enable when
          // Debug.todo has been removed
          optimize: false,
          cwd: ROOT,
          debug: false,
        },
      },
    ],
  },
});
