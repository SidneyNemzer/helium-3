const chalk = require("chalk");
const webpack = require("webpack");
const WebpackDevServer = require("webpack-dev-server");

const createConfig = require("../webpack.config");
const devServerConfig = require("./lib/webpack-dev-server.config");
const formatMessage = require("./lib/formatWepbackMessage");

const config = createConfig(null, {});
const compiler = webpack(config);

const PORT = 8080;
const DEV_SERVER_ORIGIN = `http://localhost:${PORT}/`;

compiler.hooks.invalid.tap("invalid", () => {
  clearConsole();
  console.log("Compiling...");
});

const watching = compiler.watch({}, (err, stats) => {
  if (err) {
    console.error(err);
  }

  const statsData = stats.toJson({
    all: false,
    warnings: true,
    errors: true,
  });

  if (statsData.errors.length) {
    console.log(chalk.red("Failed to compile.\n"));
    printPages();
    console.log();
    console.log(statsData.errors.map(formatMessage).join("\n\n"));
  } else if (statsData.warnings.length) {
    console.log(chalk.yellow("Compiled with warnings.\n"));
    printPages();
    console.log();
    console.log(statsData.warnings.map(formatMessage).join("\n\n"));
  } else {
    printPages();
  }
});

const devServer = new WebpackDevServer(compiler, devServerConfig);

devServer.listen(PORT, (err) => {
  if (err) {
    return console.error(err);
  }

  clearConsole();

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

const clearConsole = () => {
  process.stdout.write("\x1B[2J\x1B[3J\x1B[H");
};

const printPages = () => {
  console.log("Pages:");

  Object.keys(config.entry).map((chunkName) => {
    console.log(chalk.blue(`${DEV_SERVER_ORIGIN}${chunkName}.html`));
  });
};
