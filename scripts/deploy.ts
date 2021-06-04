import dotenv from "dotenv";
import * as childProcess from "child_process";
import * as path from "path";

dotenv.config({ path: ".env.deploy" });

const PROJECT_ROOT = path.resolve(__dirname, "..");
const BUILD_DIRECTORY = "build";

const EXPECTED_ENV = ["SERVER_IP", "SERVER_USERNAME", "SERVER_DIRECTORY"];

const missingEnv = [];
for (const name of EXPECTED_ENV) {
  if (!process.env[name]) {
    missingEnv.push(name);
  }
}

if (missingEnv.length) {
  console.error("Missing environment variable(s):", missingEnv.join(", "));
  console.error("Check .env.deploy");
  console.error();
  process.exit(1);
}

const main = async () => {
  // TODO remove old files
  copyFile("package.json");
  copyFile("package-lock.json");
  copyDirectory("build");
  // TODO npm i --production
  // TODO restart server
  //  NODE_ENV=production PORT=80 node ./build
};

const copyFile = (...parts: string[]) => {
  const source = path.resolve(PROJECT_ROOT, ...parts);
  const destination = `${process.env.SERVER_DIRECTORY}${parts.join("/")}`;
  const destinationWithLogin = `${process.env.SERVER_USERNAME}@${process.env.SERVER_IP}:${destination}`;
  execSync("scp", [source, destinationWithLogin]);
};

const copyDirectory = (...parts: string[]) => {
  const source = path.resolve(PROJECT_ROOT, ...parts);
  const destination = `${process.env.SERVER_DIRECTORY}${parts.join("/")}`;
  const destinationWithLogin = `${process.env.SERVER_USERNAME}@${process.env.SERVER_IP}:${destination}`;
  execSync("scp", ["-r", source, destinationWithLogin]);
};

const execSync = (command: string, args: string[]) => {
  if (process.argv.includes("--dry-run")) {
    console.log(command, args.join(" "));
    return;
  }
  childProcess.execFileSync(command, args, {
    encoding: "utf8",
    stdio: "inherit",
  });
};

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
