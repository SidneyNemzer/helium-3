const fs = require("fs");
const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const webpack = require("webpack");

const ROOT = __dirname;
const SOURCE = "client";

const environments = {
  development: {
    SOCKET_IO_URL: "http://localhost:3000",
    PROTOCOL_VERSION: "1",
  },
  production: {
    SOCKET_IO_URL: "/",
    PROTOCOL_VERSION: "1",
  },
};

module.exports = (_, args) => {
  const mode = args.mode || "development";

  if (!environments[mode]) {
    console.error("Invalid mode:", mode);
    console.error("Expected one of:", Object.keys(environments).join(", "));
    process.exit(1);
  }

  const isDev = mode === "development";
  const env = environments[mode];
  const processedEnv = Object.entries(env)
    .map(([key, value]) => ({
      key: `process.env.${key}`,
      value: JSON.stringify(value),
    }))
    .reduce((obj, { key, value }) => {
      obj[key] = value;
      return obj;
    }, {});

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
              isDev && path.resolve(ROOT, SOURCE, "Server.elm"),
            ].filter(Boolean),
          },
        },
      ],
    },

    plugins: [
      new webpack.DefinePlugin(processedEnv),
      ...entries.map(
        ({ name }) =>
          new HtmlWebpackPlugin({
            filename: name + ".html",
            chunks: [name],
            template: path.resolve(ROOT, SOURCE, "Page", name + ".html"),
          })
      ),
    ],
  };
};
