/**
 * Terminal Detection Adapter - yazi-like protocol detection
 * Detects terminal and selects best image protocol
 */

import type { TerminalCapabilities, ImageProtocol } from "../../domain/models/types";
import type { TerminalDetectionPort } from "../../domain/ports";

// ============================================================================
// Terminal Detection Implementation (like yazi)
// ============================================================================

export class TerminalDetection implements TerminalDetectionPort {
  private cachedCapabilities: TerminalCapabilities | null = null;

  detect(): TerminalCapabilities {
    if (this.cachedCapabilities) {
      return this.cachedCapabilities;
    }

    const tmux = this.isInsideTmux();
    const zellij = this.isInsideZellij();
    const wsl = this.isInsideWsl();

    // Get available protocols in priority order
    const supported = this.getSupportedProtocols(tmux, zellij);

    // Select best protocol
    let protocol: ImageProtocol;
    if (zellij) {
      // Zellij only supports Sixel (passthrough limitations)
      protocol = supported.includes("sixel") ? "sixel" : "chafa";
    } else if (tmux) {
      // Tmux doesn't support kgp_old (chunked upload)
      protocol = supported.find(p => p !== "kgp_old") || "chafa";
    } else {
      protocol = supported[0] || "chafa";
    }

    this.cachedCapabilities = {
      protocol,
      supported,
      maxImageWidth: 800,
      maxImageHeight: 600,
      tmux,
      zellij,
      wsl,
    };

    return this.cachedCapabilities;
  }

  getProtocol(): ImageProtocol {
    return this.detect().protocol;
  }

  isInsideTmux(): boolean {
    return !!process.env.TMUX;
  }

  isInsideZellij(): boolean {
    return !!process.env.ZELLIJ_SESSION_NAME;
  }

  isInsideWsl(): boolean {
    if (process.platform !== "linux") return false;
    try {
      const fs = require("fs");
      const content = fs.readFileSync("/proc/version", "utf-8").toLowerCase();
      return content.includes("microsoft");
    } catch {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Protocol Detection (like yazi)
  // --------------------------------------------------------------------------

  private getSupportedProtocols(tmux: boolean, zellij: boolean): ImageProtocol[] {
    const protocols: ImageProtocol[] = [];

    // Check terminal
    const term = process.env.TERM || "";
    const termProgram = process.env.TERM_PROGRAM || "";
    const termProgramVersion = process.env.TERM_PROGRAM_VERSION || "";

    // Kitty protocol
    if (this.detectKitty(term, termProgram)) {
      if (!tmux) {
        // Kgp (unicode placeholders) - newer terminals
        protocols.push("kgp");
      }
      // KgpOld (chunked upload) - doesn't work in tmux
      if (!tmux) {
        protocols.push("kgp_old");
      }
    }

    // Inline Images Protocol (iTerm2/WezTerm)
    if (this.detectIip(termProgram)) {
      protocols.push("iip");
    }

    // Sixel
    if (this.detectSixel(term, termProgram)) {
      protocols.push("sixel");
    }

    // Überzug++ (X11/Wayland)
    if (this.detectUeberzug()) {
      if (this.isWayland()) {
        protocols.push("wayland");
      } else if (this.isX11()) {
        protocols.push("x11");
      }
    }

    // Chafa (ASCII fallback)
    if (this.detectChafa()) {
      protocols.push("chafa");
    }

    return protocols;
  }

  private detectKitty(term: string, termProgram: string): boolean {
    return (
      termProgram.toLowerCase().includes("kitty") ||
      term.toLowerCase().includes("kitty") ||
      !!process.env.KITTY_PID
    );
  }

  private detectIip(termProgram: string): boolean {
    return (
      termProgram.toLowerCase().includes("iterm2") ||
      process.env.TERM_PROGRAM === "WezTerm" ||
      process.env.TERM_PROGRAM === "Warp" ||
      process.env.TERM_PROGRAM === "Tabby" ||
      process.env.TERM_PROGRAM === "Hyper" ||
      process.env.VSCODE_INJECTION === "1"
    );
  }

  private detectSixel(term: string, termProgram: string): boolean {
    return (
      term.includes("sixel") ||
      (termProgram.toLowerCase().includes("foot") && !process.env.NO_COLOR) ||
      process.env.TERM_PROGRAM === "Windows Terminal"
    );
  }

  private detectUeberzug(): boolean {
    // Überzug++ is available if XDG_SESSION_TYPE is set
    return !!process.env.XDG_SESSION_TYPE;
  }

  private detectChafa(): boolean {
    // Chafa is always considered available as last resort
    return true;
  }

  private isX11(): boolean {
    return process.env.XDG_SESSION_TYPE === "x11" || !!process.env.DISPLAY;
  }

  private isWayland(): boolean {
    return process.env.XDG_SESSION_TYPE === "wayland" || !!process.env.WAYLAND_DISPLAY;
  }

  getTerminalInfo(): {
    term?: string;
    termProgram?: string;
    termProgramVersion?: string;
    tmux?: boolean;
    zellij?: boolean;
    wsl?: boolean;
    xdgSessionType?: string;
  } {
    return {
      term: process.env.TERM,
      termProgram: process.env.TERM_PROGRAM,
      termProgramVersion: process.env.TERM_PROGRAM_VERSION,
      tmux: this.isInsideTmux(),
      zellij: this.isInsideZellij(),
      wsl: this.isInsideWsl(),
      xdgSessionType: process.env.XDG_SESSION_TYPE,
    };
  }
}
