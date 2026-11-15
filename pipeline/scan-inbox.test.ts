import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { request, type Server } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, test } from "node:test";
import { safeName, startScanInbox } from "./scan-inbox.ts";

let server: Server;
let base: string;
let dir: string;

before(async () => {
  dir = mkdtempSync(join(tmpdir(), "scan-inbox-"));
  server = await startScanInbox({ port: 0, dir, log: () => {} });
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}`;
});

after(() => {
  server.close();
  rmSync(dir, { recursive: true, force: true });
});

test("a posted zip is saved whole under its name", async () => {
  const body = Buffer.from("PK fake zip bytes ".repeat(1000));
  const res = await fetch(`${base}/scan?name=scan-20261115-0800`, { method: "POST", body });
  assert.equal(res.status, 201);
  const reply = (await res.json()) as { saved: string; bytes: number };
  assert.equal(reply.saved, "scan-20261115-0800.zip");
  assert.equal(reply.bytes, body.length);
  assert.deepEqual(readFileSync(join(dir, reply.saved)), body);
});

test("a second scan with the same name doesn't overwrite the first", async () => {
  const first = await fetch(`${base}/scan?name=twice`, { method: "POST", body: "one" });
  const second = await fetch(`${base}/scan?name=twice`, { method: "POST", body: "two" });
  assert.equal(((await first.json()) as { saved: string }).saved, "twice.zip");
  assert.equal(((await second.json()) as { saved: string }).saved, "twice-2.zip");
  assert.equal(readFileSync(join(dir, "twice.zip"), "utf8"), "one");
});

test("a name can't climb out of the inbox", async () => {
  const res = await fetch(`${base}/scan?name=../../etc/passwd`, { method: "POST", body: "x" });
  assert.equal(((await res.json()) as { saved: string }).saved, "etcpasswd.zip");
  assert.ok(existsSync(join(dir, "etcpasswd.zip")));
  assert.equal(safeName(null), "scan");
  assert.equal(safeName("a/b\\c..d"), "abcd");
});

test("an upload declared over 1 GB is refused before any of it is read", async () => {
  const status = await new Promise<number>((done, fail) => {
    const req = request(`${base}/scan?name=huge`, { method: "POST", headers: { "content-length": String(2 ** 31) } });
    req.on("response", (res) => {
      res.resume();
      done(res.statusCode ?? 0);
      req.destroy();
    });
    req.on("error", fail);
    req.flushHeaders();
  });
  assert.equal(status, 413);
  assert.ok(!readdirSync(dir).some((file) => file.startsWith("huge")));
});

test("a dropped upload leaves no file behind", async () => {
  const req = request(`${base}/scan?name=dropped`, { method: "POST", headers: { "content-length": "100000" } });
  req.on("error", () => {});
  req.write(Buffer.alloc(1000));
  await new Promise((wait) => setTimeout(wait, 50));
  req.destroy();
  for (let tries = 0; tries < 20 && readdirSync(dir).some((file) => file.startsWith("dropped")); tries++) {
    await new Promise((wait) => setTimeout(wait, 50));
  }
  assert.deepEqual(readdirSync(dir).filter((file) => file.startsWith("dropped")), []);
});

test("only POST /scan writes anything", async () => {
  const before = readdirSync(dir).length;
  assert.equal((await fetch(`${base}/nope`, { method: "POST", body: "x" })).status, 404);
  assert.equal((await fetch(`${base}/`)).status, 200);
  assert.equal(readdirSync(dir).length, before);
});
