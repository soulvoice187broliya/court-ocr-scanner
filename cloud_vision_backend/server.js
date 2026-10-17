import express from 'express';

const app = express();
app.use(express.json({ limit: '20mb' }));

const apiKey = process.env.GOOGLE_CLOUD_VISION_API_KEY;
if (!apiKey) {
  console.error('Missing GOOGLE_CLOUD_VISION_API_KEY environment variable.');
  process.exit(1);
}

app.get('/health', (_req, res) => res.json({ ok: true }));

app.post('/ocr', async (req, res) => {
  try {
    const imageBase64 = req.body?.imageBase64;
    if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
      return res.status(400).json({ error: 'imageBase64 is required' });
    }
    // Prevent accidental huge uploads; adjust only if the deployment requires it.
    if (imageBase64.length > 18_000_000) {
      return res.status(413).json({ error: 'Image is too large; use a smaller image.' });
    }
    const hints = Array.isArray(req.body?.languageHints)
      ? req.body.languageHints.filter((x) => ['en', 'hi'].includes(x))
      : ['en', 'hi'];
    const visionResponse = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${encodeURIComponent(apiKey)}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requests: [{
            image: { content: imageBase64 },
            features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
            imageContext: { languageHints: hints.length ? hints : ['en', 'hi'] }
          }]
        })
      }
    );
    const data = await visionResponse.json();
    if (!visionResponse.ok) {
      return res.status(502).json({ error: 'Google Cloud Vision request failed', details: data });
    }
    const result = data?.responses?.[0];
    if (result?.error) return res.status(502).json({ error: result.error.message });
    const text = result?.fullTextAnnotation?.text ?? result?.textAnnotations?.[0]?.description ?? '';
    return res.json({ text, detectedLanguages: result?.fullTextAnnotation?.pages?.flatMap(
      (p) => p.blocks?.flatMap((b) => b.paragraphs?.flatMap((para) =>
        para.words?.flatMap((w) => w.property?.detectedLanguages?.map((l) => l.languageCode) ?? []) ?? []) ?? []) ?? []
    ) ?? [] });
  } catch (error) {
    return res.status(500).json({ error: 'OCR backend error', details: String(error) });
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', () => console.log(`Cloud Vision OCR backend listening on ${port}`));
