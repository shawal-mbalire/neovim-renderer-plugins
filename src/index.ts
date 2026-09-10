/**
 * Composition Root - Main entry point
 * Wires together all plugins and adapters
 */

import { createMarkdownPlugin } from "../plugins/markdown";
import { createIpynbPlugin } from "../plugins/ipynb";
import { createImagePlugin } from "../plugins/image";
import type { RenderResult, PluginMessage } from "../shared/domain/models/types";

// ============================================================================
// Plugin Instances
// ============================================================================

const markdownPlugin = createMarkdownPlugin();
const ipynbPlugin = createIpynbPlugin();
const imagePlugin = createImagePlugin();

// ============================================================================
// Message Handler
// ============================================================================

interface IncomingMessage {
  type: "update" | "open" | "render" | "error";
  content?: string;
  filetype?: string;
  path?: string;
}

function handleMessage(msg: IncomingMessage): void {
  let result: RenderResult | null = null;

  try {
    switch (msg.type) {
      case "update":
        if (msg.content && msg.filetype) {
          result = processContent(msg.content, msg.filetype);
        }
        break;

      case "open":
        if (msg.path) {
          result = processFile(msg.path);
        }
        break;

      default:
        sendError(`Unknown message type: ${msg.type}`);
        return;
    }

    if (result) {
      sendRenderResult(result);
    }
  } catch (error) {
    sendError(error instanceof Error ? error.message : "Unknown error");
  }
}

// ============================================================================
// Processing Functions
// ============================================================================

function processContent(content: string, filetype: string): RenderResult {
  switch (filetype) {
    case "markdown":
    case "md":
      return markdownPlugin.process(content);

    case "ipynb":
      return ipynbPlugin.process(content);

    case "html":
    case "htm":
      // HTML is handled by markdown plugin's HTML converter
      return markdownPlugin.process(content);

    default:
      return markdownPlugin.process(content);
  }
}

function processFile(path: string): RenderResult {
  const fs = require("fs");
  const content = fs.readFileSync(path, "utf-8");

  if (path.endsWith(".ipynb")) {
    return ipynbPlugin.process(content);
  }

  return markdownPlugin.process(content);
}

// ============================================================================
// Communication Functions
// ============================================================================

function sendRenderResult(result: RenderResult): void {
  const message: PluginMessage = {
    type: "render",
    data: result,
  };
  process.stdout.write(JSON.stringify(message) + "\n");
}

function sendError(message: string): void {
  const error: PluginMessage = {
    type: "error",
    message,
  };
  process.stdout.write(JSON.stringify(error) + "\n");
}

// ============================================================================
// Input Handler
// ============================================================================

let buffer = "";

process.stdin.on("data", (chunk: Buffer) => {
  buffer += chunk.toString();

  // Process complete messages (newline-delimited JSON)
  const lines = buffer.split("\n");
  buffer = lines.pop() || "";

  for (const line of lines) {
    if (line.trim()) {
      try {
        const msg = JSON.parse(line) as IncomingMessage;
        handleMessage(msg);
      } catch (error) {
        sendError(`Invalid JSON: ${error instanceof Error ? error.message : "unknown error"}`);
      }
    }
  }
});

process.stdin.on("end", () => {
  process.exit(0);
});

// ============================================================================
// Export for testing
// ============================================================================

export { markdownPlugin, ipynbPlugin, imagePlugin, processContent, processFile };
