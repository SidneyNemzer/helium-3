const path = require("path");

// Workaround: Worker cannot import non-js files
// https://wanago.io/2019/05/06/node-js-typescript-12-worker-threads/

require("ts-node").register();
require(path.resolve(__dirname, "./worker.ts"));
