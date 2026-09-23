#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repositories = [root, resolve(root, "gateway"), resolve(root, "wolf3d")];
const failures = [];
let fileCount = 0;

function markdownFiles(repository, directory = repository) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const relativePath = relative(repository, join(directory, entry.name));
    const firstSegment = relativePath.split("/", 1)[0];
    if ([".git", ".local", "node_modules"].includes(entry.name)) continue;
    if (repository === root && ["gateway", "wolf3d"].includes(firstSegment)) continue;
    if (repository.endsWith("/wolf3d") && firstSegment === "runtime") continue;
    if (entry.isDirectory()) files.push(...markdownFiles(repository, join(directory, entry.name)));
    if (entry.isFile() && entry.name.endsWith(".md")) files.push(relativePath);
  }
  return files;
}

for (const repository of repositories) {
  const repositoryName = repository === root ? "platform" : repository.split("/").at(-1);
  for (const relativeFile of markdownFiles(repository)) {
    fileCount += 1;
    const file = resolve(repository, relativeFile);
    const markdown = readFileSync(file, "utf8");
    const links = markdown.matchAll(/!?\[[^\]]*\]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)/g);

    for (const match of links) {
      const target = match[1];
      if (/^(?:[a-z][a-z0-9+.-]*:|#)/i.test(target)) continue;

      const path = decodeURIComponent(target.split(/[?#]/, 1)[0]);
      if (path && !existsSync(resolve(dirname(file), path))) {
        failures.push(`${repositoryName}/${relativeFile}: missing ${target}`);
      }
    }
  }
}

if (failures.length) {
  for (const failure of failures) console.error(`documentation check: ${failure}`);
  process.exit(1);
}

console.log(`verified local links and images in ${fileCount} Markdown files`);
