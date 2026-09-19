import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = parseInt(process.env.PORT || "5097", 10);
const HOST = "0.0.0.0";
const DIST_DIR = path.resolve(__dirname, "dist");

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".txt": "text/plain; charset=utf-8",
};

const server = http.createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== "GET" && req.method !== "HEAD") {
    res.writeHead(405, { "Content-Type": "text/plain" });
    res.end("Method Not Allowed");
    return;
  }

  const urlPath = decodeURIComponent(new URL(req.url || "/", `http://${req.headers.host}`).pathname);
  let safePath = path.normalize(urlPath).replace(/^(\.\.[\/\\])+/, "");
  let filePath = path.join(DIST_DIR, safePath);

  fs.stat(filePath, (err, stats) => {
    if (!err && stats.isFile()) {
      serveFile(filePath, res, req.method === "HEAD");
      return;
    }

    if (!err && stats.isDirectory()) {
      const indexPath = path.join(filePath, "index.html");
      if (fs.existsSync(indexPath)) {
        serveFile(indexPath, res, req.method === "HEAD");
        return;
      }
    }

    // SPA fallback
    const fallbackIndex = path.join(DIST_DIR, "index.html");
    if (fs.existsSync(fallbackIndex)) {
      serveFile(fallbackIndex, res, req.method === "HEAD");
      return;
    }

    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("404 Not Found");
  });
});

function serveFile(filePath, res, isHead) {
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || "application/octet-stream";

  const isHashedAsset = filePath.includes(`${path.sep}assets${path.sep}`);
  if (isHashedAsset) {
    res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
  } else {
    res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
  }

  res.setHeader("Content-Type", contentType);
  res.setHeader("X-Content-Type-Options", "nosniff");

  if (isHead) {
    res.writeHead(200);
    res.end();
    return;
  }

  const stream = fs.createReadStream(filePath);
  stream.on("error", () => {
    if (!res.headersSent) {
      res.writeHead(500, { "Content-Type": "text/plain" });
      res.end("Internal Server Error");
    }
  });
  stream.pipe(res);
}

server.listen(PORT, HOST, () => {
  console.log(`[Superadmin Server] Serving on http://${HOST}:${PORT}`);
});
