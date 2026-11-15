// The laptop's scan inbox: the phone's "Send to laptop" posts one zip here, and it lands in pipeline/inbox/ for the
// trip to the Spark (pipeline/README.md). Plain node:http, no packages. Like the relay, anyone on the hotspot can
// reach it; it only ever writes new zip files into its own folder.
import { createWriteStream, existsSync, mkdirSync } from "node:fs";
import { rename, rm } from "node:fs/promises";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import { networkInterfaces } from "node:os";
import { basename, join, resolve } from "node:path";
import { Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import { fileURLToPath } from "node:url";

// A 400-photo scan at full resolution is about 200 MB; this leaves room without letting a stray upload fill the disk.
const MAX_BYTES = 1024 ** 3;

// The name becomes a file name, so only plain characters survive (no slashes, no "..").
export function safeName(raw: string | null): string {
  const cleaned = (raw ?? "").replace(/[^A-Za-z0-9_-]/g, "").slice(0, 64);
  return cleaned || "scan";
}

function freePath(dir: string, name: string): string {
  let candidate = join(dir, `${name}.zip`);
  for (let n = 2; existsSync(candidate); n++) candidate = join(dir, `${name}-${n}.zip`);
  return candidate;
}

function reply(res: ServerResponse, status: number, body: object): void {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

async function receive(req: IncomingMessage, res: ServerResponse, dir: string, log: (line: string) => void) {
  const declared = Number(req.headers["content-length"] ?? 0);
  if (declared > MAX_BYTES) return reply(res, 413, { error: `over ${MAX_BYTES} bytes` });

  const name = safeName(new URL(req.url ?? "/", "http://inbox").searchParams.get("name"));
  const target = freePath(dir, name);
  const partial = `${target}.part`;
  let bytes = 0;
  const counter = new Transform({
    transform(chunk: Buffer, _encoding, done) {
      bytes += chunk.length;
      done(bytes > MAX_BYTES ? new Error(`over ${MAX_BYTES} bytes`) : null, chunk);
    },
  });
  try {
    // "wx": two uploads racing for the same name fail instead of interleaving into one file.
    await pipeline(req, counter, createWriteStream(partial, { flags: "wx" }));
    // Renamed only once complete, so a dropped upload never looks like a finished scan.
    await rename(partial, target);
  } catch (error) {
    await rm(partial, { force: true });
    log(`upload failed: ${(error as Error).message}`);
    if (!res.headersSent) reply(res, 400, { error: (error as Error).message });
    return;
  }
  const saved = basename(target);
  log(`received ${saved} (${(bytes / 1024 ** 2).toFixed(1)} MB)`);
  reply(res, 201, { saved, bytes });
}

export function startScanInbox(options: { port?: number; dir: string; log?: (line: string) => void }): Promise<Server> {
  const { port = 8090, dir, log = console.log } = options;
  mkdirSync(dir, { recursive: true });
  const server = createServer((req, res) => {
    const path = new URL(req.url ?? "/", "http://inbox").pathname;
    if (req.method === "POST" && path === "/scan") return void receive(req, res, dir, log);
    if (req.method === "GET" && path === "/") return reply(res, 200, { inbox: "POST a scan zip to /scan?name=…" });
    reply(res, 404, { error: "not found" });
  });
  return new Promise((ready) => server.listen(port, () => ready(server)));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const portFlag = process.argv.indexOf("--port");
  const port = portFlag > 0 ? Number(process.argv[portFlag + 1]) : 8090;
  const dir = fileURLToPath(new URL("./inbox/", import.meta.url)).replace(/[\\/]$/, "");
  const server = await startScanInbox({ port, dir });
  const actual = (server.address() as { port: number }).port;
  const addresses = Object.values(networkInterfaces())
    .flat()
    .flatMap((address) => (address?.family === "IPv4" && !address.internal ? [`http://${address.address}:${actual}/scan`] : []));
  console.log(`scan inbox saving to ${dir}`);
  for (const address of addresses) console.log(`  ${address}`);
}
