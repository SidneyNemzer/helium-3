const path = require("path");

const ROOT = __dirname;
const SOURCE = "client";

module.exports = (env, args) => ({
  mode: args.mode || "development",

  entry: path.resolve(ROOT, SOURCE, "Server.entry.js"),

  output: {
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
        loader: "elm-webpack-loader",
        options: {
          cwd: ROOT,
          debug: false,
        },
      },
    ],
  },
});
