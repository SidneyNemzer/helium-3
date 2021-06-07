import dotenv from "dotenv";
import * as childProcess from "child_process";
import * as path from "path";

dotenv.config({ path: ".env.deploy" });

/**
 * Converts a Windows path to Posix. If the path is already Posix, the path
 * is returned unchanged.
 */
const toPosixPath = (input: string) => {
  if (input.includes("/")) {
    return input;
  }

  const parts = input.split("\\");

  if (parts[0] && parts[0].includes(":")) {
    parts[0] = parts[0].replace(":", "").toLowerCase();
    // Ensure returned path starts with a slash
    parts.unshift("");
  }

  return parts.join("/");
};

const PROJECT_ROOT = toPosixPath(path.resolve(__dirname, ".."));
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
  copyFile("pm2.yaml");
  copyDirectory(BUILD_DIRECTORY);
  // TODO npm i --production
  // TODO restart server
  //  NODE_ENV=production PORT=80 node ./build
};

const copyFile = (...parts: string[]) => {
  const source = path.posix.resolve(PROJECT_ROOT, ...parts);
  const destination = [
    process.env.SERVER_USERNAME,
    "@",
    process.env.SERVER_IP,
    ":",
    process.env.SERVER_DIRECTORY,
    parts.join("/"),
  ].join("");
  execSync("scp", [source, destination]);
};

const copyDirectory = (...parts: string[]) => {
  // TODO this will not handle subdirectories like `stuff/things`. It will be
  // created at `/root/helium3/things` instead of `/root/helium3/stuff/things`.
  const source = path.posix.resolve(PROJECT_ROOT, ...parts);
  const destination = [
    process.env.SERVER_USERNAME,
    "@",
    process.env.SERVER_IP,
    ":",
    process.env.SERVER_DIRECTORY,
  ].join("");
  execSync("scp", ["-r", source, destination]);
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
