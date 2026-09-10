/**
 * Output Renderer Adapter - Full VSCode Feature Parity
 * Renders all VSCode-supported output types
 */

import type { Output, OutputData } from "../../domain/models/types";
import type { OutputRendererPort } from "../../domain/ports";

// ============================================================================
// VSCode Output MIME Types (Priority Order)
// ============================================================================

const DISPLAY_ORDER = [
  "application/vnd.code.notebook.error",
  "application/vnd.code.notebook.stdout",
  "application/vnd.code.notebook.stderr",
  "application/x.notebook.stdout",
  "application/x.notebook.stderr",
  "application/x.notebook.stream",
  "image/svg+xml",
  "text/html",
  "application/javascript",
  "image/png",
  "image/jpeg",
  "image/gif",
  "text/latex",
  "application/json",
  "text/plain",
  "text/markdown",
];

// ============================================================================
// Output Renderer Implementation
// ============================================================================

export class OutputRenderer implements OutputRendererPort {
  renderStream(text: string[]): string[] {
    return text.map((line) => line.replace(/\n$/, ""));
  }

  renderExecuteResult(data: Record<string, unknown>, execution_count?: number): string[] {
    const lines: string[] = [];
    if (execution_count !== undefined) {
      lines.push(`Out [${execution_count}]:`);
    }
    const text = this.extractBestText(data);
    lines.push(...text);
    return lines;
  }

  renderDisplayData(data: Record<string, unknown>): string[] {
    return this.extractBestText(data);
  }

  renderError(ename: string, evalue: string, traceback: string[]): string[] {
    const lines: string[] = [];
    if (traceback && traceback.length > 0) {
      for (const line of traceback) {
        lines.push(this.stripAnsi(line));
      }
    } else {
      lines.push(`${ename}: ${evalue}`);
    }
    return lines;
  }

  renderImage(data: string, format: string): string[] {
    return [`[Image: ${format.toUpperCase()} - ${data.length} bytes base64]`];
  }

  renderSvg(svg: string): string[] {
    const lines: string[] = [];
    lines.push("[SVG Image]");
    const textMatches = svg.match(/<text[^>]*>(.*?)<\/text>/g);
    if (textMatches) {
      lines.push("  Text content:");
      for (const match of textMatches.slice(0, 10)) {
        const text = match.replace(/<[^>]+>/g, "").trim();
        if (text) lines.push(`    ${text}`);
      }
    }
    return lines;
  }

  renderHtml(html: string[]): string[] {
    const combined = html.join("\n");
    return this.htmlToText(combined);
  }

  renderJson(json: string): string[] {
    try {
      const parsed = JSON.parse(json);
      const formatted = JSON.stringify(parsed, null, 2);
      return formatted.split("\n");
    } catch {
      return [json];
    }
  }

  renderLatex(latex: string[]): string[] {
    const combined = latex.join("\n");
    return [`[LaTeX: ${combined.substring(0, 100)}${combined.length > 100 ? "..." : ""}]`];
  }

  renderJavascript(js: string[]): string[] {
    return js.map((line) => line.replace(/\n$/, ""));
  }

  renderMarkdown(md: string[]): string[] {
    return md.map((line) => line.replace(/\n$/, ""));
  }

  renderOutput(output: Output): string[] {
    switch (output.output_type) {
      case "stream":
        return this.renderStream(output.text || []);
      case "execute_result":
        return this.renderExecuteResult(
          (output.data as Record<string, unknown>) || {},
          output.execution_count
        );
      case "display_data":
        return this.renderDisplayData((output.data as Record<string, unknown>) || {});
      case "error":
        return this.renderError(
          output.ename || "Error",
          output.evalue || "",
          output.traceback || []
        );
      default:
        return ["[Unknown output type]"];
    }
  }

  // --------------------------------------------------------------------------
  // Best Text Extraction (VSCode priority order)
  // --------------------------------------------------------------------------

  private extractBestText(data: Record<string, unknown>): string[] {
    // Try each MIME type in VSCode display order
    for (const mime of DISPLAY_ORDER) {
      if (data[mime]) {
        const content = data[mime];
        if (typeof content === "string") {
          return content.split("\n").filter((l) => l.trim() !== "");
        }
        if (Array.isArray(content)) {
          return content.map((l) => l.replace(/\n$/, ""));
        }
      }
    }
    return ["[No displayable output]"];
  }

  // --------------------------------------------------------------------------
  // HTML to Text Conversion
  // --------------------------------------------------------------------------

  private htmlToText(html: string): string[] {
    let text = html;

    // Replace common HTML elements
    text = text.replace(/<br\s*\/?>/gi, "\n");
    text = text.replace(/<\/p>/gi, "\n\n");
    text = text.replace(/<\/div>/gi, "\n");
    text = text.replace(/<\/tr>/gi, "\n");
    text = text.replace(/<\/td>/gi, " | ");
    text = text.replace(/<\/th>/gi, " | ");
    text = text.replace(/<hr\s*\/?>/gi, "\n---\n");

    // Remove style and script tags
    text = text.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "");
    text = text.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "");

    // Convert table structure
    text = text.replace(/<table[^>]*>/gi, "\n");
    text = text.replace(/<\/table>/gi, "\n");
    text = text.replace(/<thead[^>]*>/gi, "");
    text = text.replace(/<\/thead>/gi, "");
    text = text.replace(/<tbody[^>]*>/gi, "");
    text = text.replace(/<\/tbody>/gi, "");
    text = text.replace(/<tr[^>]*>/gi, "");
    text = text.replace(/<td[^>]*>/gi, " ");
    text = text.replace(/<th[^>]*>/gi, " ");

    // Convert lists
    text = text.replace(/<ul[^>]*>/gi, "\n");
    text = text.replace(/<\/ul>/gi, "\n");
    text = text.replace(/<ol[^>]*>/gi, "\n");
    text = text.replace(/<\/ol>/gi, "\n");
    text = text.replace(/<li[^>]*>/gi, "• ");

    // Convert headings
    text = text.replace(/<h1[^>]*>/gi, "\n# ");
    text = text.replace(/<\/h1>/gi, "\n");
    text = text.replace(/<h2[^>]*>/gi, "\n## ");
    text = text.replace(/<\/h2>/gi, "\n");
    text = text.replace(/<h3[^>]*>/gi, "\n### ");
    text = text.replace(/<\/h3>/gi, "\n");
    text = text.replace(/<h4[^>]*>/gi, "\n#### ");
    text = text.replace(/<\/h4>/gi, "\n");
    text = text.replace(/<h5[^>]*>/gi, "\n##### ");
    text = text.replace(/<\/h5>/gi, "\n");
    text = text.replace(/<h6[^>]*>/gi, "\n###### ");
    text = text.replace(/<\/h6>/gi, "\n");

    // Convert formatting
    text = text.replace(/<strong[^>]*>/gi, "**");
    text = text.replace(/<\/strong>/gi, "**");
    text = text.replace(/<b[^>]*>/gi, "**");
    text = text.replace(/<\/b>/gi, "**");
    text = text.replace(/<em[^>]*>/gi, "*");
    text = text.replace(/<\/em>/gi, "*");
    text = text.replace(/<i[^>]*>/gi, "*");
    text = text.replace(/<\/i>/gi, "*");
    text = text.replace(/<code[^>]*>/gi, "`");
    text = text.replace(/<\/code>/gi, "`");
    text = text.replace(/<pre[^>]*>/gi, "\n```\n");
    text = text.replace(/<\/pre>/gi, "\n```\n");

    // Convert links
    text = text.replace(/<a[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/gi, "[$2]($1)");

    // Convert images
    text = text.replace(/<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*\/?>/gi, "![Image: $2]($1)");
    text = text.replace(/<img[^>]*alt="([^"]*)"[^>]*src="([^"]*)"[^>]*\/?>/gi, "![Image: $1]($2)");
    text = text.replace(/<img[^>]*src="([^"]*)"[^>]*\/?>/gi, "![Image]($1)");

    // Remove all other HTML tags
    text = text.replace(/<[^>]+>/g, "");

    // Decode HTML entities
    text = text
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/&nbsp;/g, " ")
      .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(parseInt(dec, 10)))
      .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCharCode(parseInt(hex, 16)));

    // Clean up whitespace
    text = text.replace(/\n\s*\n\s*\n/g, "\n\n");

    return text.split("\n").filter((line) => line.trim() !== "");
  }

  private stripAnsi(text: string): string {
    // eslint-disable-next-line no-control-regex
    return text.replace(/\x1B\[[0-9;]*[mGlHJ]/g, "");
  }
}
