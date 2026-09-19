import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = parseInt(process.env.PORT || "5096", 10);
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
  // Support CORS and public access
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

  // Check if file exists
  fs.stat(filePath, (err, stats) => {
    if (!err && stats.isFile()) {
      serveFile(filePath, res, req.method === "HEAD");
      return;
    }

    // If directory, check index.html inside
    if (!err && stats.isDirectory()) {
      const subIndex = path.join(filePath, "index.html");
      if (fs.existsSync(subIndex)) {
        serveFile(subIndex, res, req.method === "HEAD");
        return;
      }
    }

    // SPA fallback to root index.html
    const rootIndex = path.join(DIST_DIR, "index.html");
    if (fs.existsSync(rootIndex)) {
      serveFile(rootIndex, res, req.method === "HEAD", true);
    } else {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Frontend build artifact (dist/index.html) not found. Run 'npm run build' first.");
    }
  });
});

function serveFile(targetFile, res, isHead, isSpaFallback = false) {
  const ext = path.extname(targetFile).toLowerCase();
  const contentType = MIME_TYPES[ext] || "application/octet-stream";

  const headers = {
    "Content-Type": contentType,
    "X-Content-Type-Options": "nosniff",
  };

  // Cache static assets aggressively, keep index.html fresh
  if (targetFile.includes("/assets/")) {
    headers["Cache-Control"] = "public, max-age=31536000, immutable";
  } else {
    headers["Cache-Control"] = "no-cache, no-store, must-revalidate";
  }

  try {
    const stat = fs.statSync(targetFile);
    headers["Content-Length"] = stat.size;

    res.writeHead(200, headers);

    if (isHead) {
      res.end();
      return;
    }

    const stream = fs.createReadStream(targetFile);
    stream.on("error", () => {
      if (!res.headersSent) {
        res.writeHead(500, { "Content-Type": "text/plain" });
      }
      res.end("Internal Server Error");
    });
    stream.pipe(res);
  } catch (e) {
    if (!res.headersSent) {
      res.writeHead(500, { "Content-Type": "text/plain" });
    }
    res.end("Internal Server Error");
  }
}

server.listen(PORT, HOST, () => {
  console.log(`MedicalCRM Admin Panel live & publicly reachable:`);
  console.log(`Local:   http://localhost:${PORT}`);
  console.log(`Network: http://134.195.138.153:${PORT}`);
});

process.on("SIGINT", () => {
  server.close(() => process.exit(0));
});
process.on("SIGTERM", () => {
  server.close(() => process.exit(0));
});
