import server from "./app";

const port = parseInt(process.env.PORT || "3000", 10);

if (Number.isNaN(port)) {
  console.error("Invalid port:", port);
  process.exit(1);
}

server.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});
