const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

function getAssemblyKey() {
  return process.env.ASSEMBLY_API_KEY ||
    (require("firebase-functions").config().assemblyapi?.key);
}

/**
 * Proxy para AssemblyAI - evita CORS en Flutter web.
 * POST con body: { audio_url: "https://..." }
 * Retorna: { text: "transcripción" } o { error: "mensaje" }
 */
exports.transcribeAudio = onRequest(
  {cors: true},
  async (req, res) => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const apiKey = getAssemblyKey();
    if (!apiKey) {
      logger.error("ASSEMBLY_API_KEY not configured");
      res.status(500).json({
        error: "Server misconfiguration: ASSEMBLY_API_KEY not set",
      });
      return;
    }

    let audioUrl;
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      audioUrl = body?.audio_url;
    } catch (e) {
      res.status(400).json({error: "Invalid JSON body"});
      return;
    }

    if (!audioUrl || typeof audioUrl !== "string") {
      res.status(400).json({error: "audio_url required"});
      return;
    }

    try {
      const submitRes = await fetch("https://api.assemblyai.com/v2/transcript", {
        method: "POST",
        headers: {
          "Authorization": apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          audio_url: audioUrl,
          language_detection: true,
        }),
      });

      const submitData = await submitRes.json();
      if (submitRes.status !== 200) {
        logger.error("AssemblyAI submit error", submitData);
        res.status(submitRes.status).json({
          error: submitData.error || "Transcription failed",
        });
        return;
      }

      const transcriptId = submitData.id;
      const pollUrl = `https://api.assemblyai.com/v2/transcript/${transcriptId}`;
      let attempts = 0;
      const maxAttempts = 60;

      while (attempts < maxAttempts) {
        await new Promise((r) => setTimeout(r, 3000));
        const pollRes = await fetch(pollUrl, {
          headers: {"Authorization": apiKey},
        });
        const pollData = await pollRes.json();

        if (pollData.status === "completed") {
          res.set("Access-Control-Allow-Origin", "*");
          res.json({text: pollData.text || ""});
          return;
        }
        if (pollData.status === "error") {
          res.status(500).json({
            error: pollData.error || "Transcription failed",
          });
          return;
        }
        attempts++;
      }

      res.status(408).json({
        error: "Transcription timeout",
      });
    } catch (err) {
      logger.error("transcribeAudio error", err);
      res.status(500).json({
        error: err.message || "Internal server error",
      });
    }
  },
);
