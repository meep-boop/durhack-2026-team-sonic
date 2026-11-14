import { networkInterfaces } from "node:os";
import { fileURLToPath } from "node:url";
import { claudeLabeller } from "./labeller.ts";
import { startRelay } from "./relay.ts";

// Off unless asked for, because every snapshot a dashboard sends is a paid Claude call.
const labeller = process.argv.includes("--labels") ? claudeLabeller() : undefined;

const relay = await startRelay({
  port: Number(process.env.PORT ?? 8080),
  statePath: fileURLToPath(new URL("./state.json", import.meta.url)),
  fresh: process.argv.includes("--fresh"),
  labeller,
});
console.log(labeller ? "labelling: on (Claude, each snapshot is billed)" : "labelling: off (start with --labels to turn it on)");

// The phone needs the laptop's address on the hotspot; localhost only works from the laptop itself.
const addresses = Object.values(networkInterfaces())
  .flat()
  .flatMap((address) => (address?.family === "IPv4" && !address.internal ? [`ws://${address.address}:${relay.port}`] : []));

console.log(`relay listening on port ${relay.port}. Connect to:`);
for (const address of [`ws://localhost:${relay.port}`, ...addresses]) console.log(`  ${address}`);
