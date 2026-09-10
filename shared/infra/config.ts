/**
 * Infrastructure Configuration
 * Centralized config loading from environment
 */

export interface AppConfig {
  // General
  logLevel: "debug" | "info" | "warn" | "error";
  debounceMs: number;

  // Graphics
  kittyEnabled: boolean;
  sixelEnabled: boolean;
  maxImageWidth: number;
  maxImageHeight: number;

  // Mermaid
  mermaidPath: string;
  mermaidTheme: string;

  // Temp files
  tempDir: string;
}

export function loadConfig(): AppConfig {
  return {
    logLevel: (process.env.LOG_LEVEL as AppConfig["logLevel"]) || "info",
    debounceMs: parseInt(process.env.DEBOUNCE_MS || "100", 10),

    kittyEnabled: process.env.KITTY_DISABLED !== "true",
    sixelEnabled: process.env.SIXEL_ENABLED === "true",
    maxImageWidth: parseInt(process.env.MAX_IMAGE_WIDTH || "800", 10),
    maxImageHeight: parseInt(process.env.MAX_IMAGE_HEIGHT || "600", 10),

    mermaidPath: process.env.MERMAID_PATH || "mmdc",
    mermaidTheme: process.env.MERMAID_THEME || "dark",

    tempDir: process.env.TEMP_DIR || "",
  };
}
