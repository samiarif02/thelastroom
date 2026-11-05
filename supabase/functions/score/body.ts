// Reading a request body with a hard byte cap (security audit 2026-11-05). `req.json()` and
// `req.text()` buffer the whole body first, and a chunked request has no content-length to
// check, so the cap is enforced on the stream itself.

/**
 * [req]'s body as UTF-8 text, or null when it is longer than [maxBytes] bytes (the rest is
 * never read). A declared content-length over the cap is refused before reading anything.
 */
export async function readCapped(req: Request, maxBytes: number): Promise<string | null> {
  const declared = Number(req.headers.get('content-length'));
  if (Number.isFinite(declared) && declared > maxBytes) {
    await req.body?.cancel();
    return null;
  }
  if (req.body === null) return '';
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel();
      return null;
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(total);
  let at = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, at);
    at += chunk.byteLength;
  }
  return new TextDecoder().decode(bytes);
}
