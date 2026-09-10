/**
 * Timing Utility
 * High-precision timing for performance measurement
 */

export function startTiming(): number {
  return performance.now();
}

export function stopTiming(startTime: number): number {
  const elapsed = performance.now() - startTime;
  return Math.floor(elapsed * 100) / 100;
}

export function formatTiming(label: string, startTime: number): string {
  const elapsed = stopTiming(startTime);
  return `${label}: ${elapsed.toFixed(2)} ms`;
}
