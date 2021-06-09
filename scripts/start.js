const chalk = require("chalk");
const webpack = require("webpack");
const WebpackDevServer = require("webpack-dev-server");

const createConfig = require("../webpack.config");
const devServerConfig = require("./lib/webpack-dev-server.config");
const formatMessage = require("./lib/formatWebpackMessage");

const config = createConfig(null, {});
const compiler = webpack(config);

const PORT = 8080;
const DEV_SERVER_ORIGIN = `http://localhost:${PORT}/`;

compiler.hooks.invalid.tap("invalid", () => {
  console.log("\nCompiling...");
});

compiler.hooks.done.tap("done", (stats) => {
  try {
    printSeparator();

    const statsData = stats.toJson({
      all: false,
      warnings: true,
      errors: true,
    });

    if (statsData.errors.length) {
      console.log(
        Array.from(new Set(statsData.errors.map(formatMessage))).join("\n\n") +
          "\n\n" +
          chalk.red("Failed to compile.") +
          "\n"
      );
    } else if (statsData.warnings.length) {
      console.log(chalk.yellow("Compiled with warnings.\n"));
      console.log();
      console.log(statsData.warnings.map(formatMessage).join("\n\n"));
    } else {
      console.log(chalk.green("Success!\n"));
    }

    printPages();
  } catch (error) {
    console.error(error);
  }
});

const devServer = new WebpackDevServer(compiler, devServerConfig);

devServer.listen(PORT, (err) => {
  if (err) {
    return console.error(err);
  }

  printSeparator();

  console.log(chalk.cyan("Starting dev server..."));
});

["SIGINT", "SIGTERM"].forEach(function (sig) {
  process.on(sig, function () {
    devServer.close();
    process.exit();
  });
});

process.stdin.on("end", function () {
  devServer.close();
  process.exit();
});

const printSeparator = () => {
  console.log("\n----------------------\n");
};

const printPages = () => {
  console.log("Pages:");

  Object.keys(config.entry).map((chunkName) => {
    console.log(chalk.blue(`${DEV_SERVER_ORIGIN}${chunkName}.html`));
  });
};
