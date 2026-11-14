// Rolling frame rate over the last `windowSize` frames. The spike's kill test is "orbit holds 30 fps on the weakest
// laptop", so the number has to be steady enough to read, not a per-frame flicker.
export function createFrameMeter(windowSize = 60) {
  const deltas: number[] = [];
  let sum = 0;
  let last: number | null = null;

  return {
    tick(nowMs: number): void {
      if (last !== null) {
        const delta = nowMs - last;
        deltas.push(delta);
        sum += delta;
        if (deltas.length > windowSize) sum -= deltas.shift()!;
      }
      last = nowMs;
    },
    fps(): number {
      return deltas.length === 0 || sum === 0 ? 0 : (1000 * deltas.length) / sum;
    },
  };
}
