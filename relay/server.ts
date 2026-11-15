import { networkInterfaces } from "node:os";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { claudeLabeller } from "./labeller.ts";
import { startRelay } from "./relay.ts";

const { values: flags } = parseArgs({
  options: { labels: { type: "boolean" }, fresh: { type: "boolean" }, state: { type: "string" } },
});

// Off unless asked for, because every snapshot a dashboard sends is a paid Claude call.
const labeller = flags.labels ? claudeLabeller() : undefined;
// A second relay on the same machine (a test, a rehearsal) needs its own file: two relays writing one file empty
// each other's saved guide.
const statePath = flags.state ? resolve(flags.state) : fileURLToPath(new URL("./state.json", import.meta.url));

const relay = await startRelay({
  port: Number(process.env.PORT ?? 8080),
  statePath,
  fresh: flags.fresh,
  labeller,
});
console.log(`state: ${statePath}`);
console.log(labeller ? "labelling: on (Claude, each snapshot is billed)" : "labelling: off (start with --labels to turn it on)");

// The phone needs the laptop's address on the hotspot; localhost only works from the laptop itself.
const addresses = Object.values(networkInterfaces())
  .flat()
  .flatMap((address) => (address?.family === "IPv4" && !address.internal ? [`ws://${address.address}:${relay.port}`] : []));

console.log(`relay listening on port ${relay.port}. Connect to:`);
for (const address of [`ws://localhost:${relay.port}`, ...addresses]) console.log(`  ${address}`);
