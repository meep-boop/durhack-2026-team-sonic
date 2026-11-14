import { networkInterfaces } from "node:os";
import { fileURLToPath } from "node:url";
import { startRelay } from "./relay.ts";

const relay = await startRelay({
  port: Number(process.env.PORT ?? 8080),
  statePath: fileURLToPath(new URL("./state.json", import.meta.url)),
  fresh: process.argv.includes("--fresh"),
});

// The phone needs the laptop's address on the hotspot; localhost only works from the laptop itself.
const addresses = Object.values(networkInterfaces())
  .flat()
  .flatMap((address) => (address?.family === "IPv4" && !address.internal ? [`ws://${address.address}:${relay.port}`] : []));

console.log(`relay listening on port ${relay.port}. Connect to:`);
for (const address of [`ws://localhost:${relay.port}`, ...addresses]) console.log(`  ${address}`);
