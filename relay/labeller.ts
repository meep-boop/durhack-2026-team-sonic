import Anthropic from "@anthropic-ai/sdk";
import type { Label, LabelsRequest } from "../contracts/protocol.ts";

export type Labeller = (request: LabelsRequest) => Promise<{ model: string; labels: Label[] }>;

const MODEL = "claude-opus-5-5";

const INSTRUCTIONS = `This is a snapshot of a 3D scan of network equipment in a small business's comms cupboard:
switches, patch panels, routers, cables and screws. A remote engineer will use your labels to tell someone on site
which part to touch, so a wrong label sends them to the wrong part.

Label each part whose name or number you can actually read in the image, such as a port number printed on a patch
panel, plus any screw or cable that is clearly visible (for example "Cover screw"). Use the text printed on the
equipment where there is any. Leave out anything you would have to guess: no label is better than a wrong one.

Give each label the pixel position of the part's centre, measured from the image's top-left corner.`;

const LABELS_SCHEMA = {
  type: "object",
  properties: {
    labels: {
      type: "array",
      items: {
        type: "object",
        properties: { text: { type: "string" }, x: { type: "integer" }, y: { type: "integer" } },
        required: ["text", "x", "y"],
        additionalProperties: false,
      },
    },
  },
  required: ["labels"],
  additionalProperties: false,
};

export function claudeLabeller(client: Anthropic = new Anthropic()): Labeller {
  return async ({ image, width, height }) => {
    const response = await client.beta.messages.create({
      model: MODEL,
      max_tokens: 16000,
      // If a safety classifier declines, the API retries on a fallback model inside the same call.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: { effort: "medium", format: { type: "json_schema", schema: LABELS_SCHEMA } },
      system: INSTRUCTIONS,
      messages: [
        {
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: image.mediaType, data: image.data } },
            { type: "text", text: `The image is ${width} x ${height} pixels. Label the parts you can read.` },
          ],
        },
      ],
    });
    if (response.stop_reason === "refusal") throw new Error("Claude declined to label this snapshot");
    if (response.stop_reason === "max_tokens") throw new Error("Claude's answer was cut off");
    const answer = response.content.find((block): block is Anthropic.Beta.BetaTextBlock => block.type === "text");
    if (!answer) throw new Error("Claude returned no labels");
    const { labels } = JSON.parse(answer.text) as { labels: Label[] };
    // The schema guarantees the shape, not that a point lies inside the picture.
    const inside = labels.filter(({ text, x, y }) => text.trim() && x >= 0 && y >= 0 && x < width && y < height);
    return { model: response.model, labels: inside };
  };
}
