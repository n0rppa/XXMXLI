export async function onRequestGet() {
  return Response.json({ ok: true, ts: Date.now(), env: 'cloudflare' });
}