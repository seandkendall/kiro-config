---
inclusion: auto
name: aws-diagram-html
description: 'Generate a polished, self-contained HTML architecture diagram (inline SVG) with real official AWS Architecture Icons, hand-routed orthogonal connectors that never cross or overlap, numbered flow steps, and an observability panel. Triggers when the user asks for a nice looking diagram, an HTML diagram, a diagram to open in the browser, or a diagram with no overlapping lines and real AWS icons.'
---

# AWS Diagram HTML (SVG, official icons, no overlapping lines)

Produces `docs/architecture.html`: one file, no network needed, opens in any browser. Verified end to end on the re:Imburse demo (see `references/make-diagram-example.py`, a complete working generator).

## Pick the right diagram skill

| User wants | Skill |
| --- | --- |
| Nice looking page to open or share, polished presentation, "html", "no overlapping lines" | **this skill** |
| A PNG for slides or a PR | `aws-diagram-png` (awsdac) |
| Editable draw.io XML | `aws-architecture-diagram` |

If the user only says "diagram" and wants it to look good, default to this skill. All three must use real AWS icons.

## Non negotiables

1. **Real AWS icons only.** Never draw lookalike shapes or use emoji. If an icon is missing, find the right one (see below).
2. **No overlapping lines.** Every connector is an orthogonal path (M, H, V commands only) that crosses no other connector, shares no segment with one, and passes through no card. This is enforced by `check_layout()` in the example script, which must pass before the HTML is written. Do not remove it.
3. **Look at the rendered result.** Render with headless Chrome, read the screenshot, fix what is wrong. A passing checker is not enough (it cannot see a frame title hidden under a card, for example).
4. **No dashes as punctuation** in any text on the page (use commas, colons, or split sentences). Compound words are fine.
5. Only data flow services get cards and connectors. Cross cutting services (CloudWatch, X-Ray, CloudFormation or SAM, IAM) go in a separate panel below with no connectors, unless the user asks to draw them in the flow.

## Getting the official icons

The AWS Architecture Icons deck is cached by `awsdac` (`brew install awsdac`). Run any `awsdac` render once to populate `~/.cache/awsdac/`. That first run downloads the icon definition YAML (`definition-for-aws-icons-light.yaml`) and, from the `Zip.Url` field inside it, the full icon deck zip, extracted alongside it in the same cache directory.

**Prerequisite:** the icon-loading code uses Pillow (`pip3 install Pillow` or `uv add pillow`) to decode and recolor the cached PNGs.

1. Find the icon file name: parse `~/.cache/awsdac/*definition-for-aws-icons-light.yaml`; each entry is `"<Service name>": ... Icon: Path: "imageNNN.png"`.
2. Read the PNG from `~/.cache/awsdac/*Light-BG*.pptx/ppt/media/<file>`.
3. Resize to 160px, base64 embed as a data URI (keeps the HTML self-contained, ~200 KB).

Known good names (service icons, 320px colored squares): Amazon API Gateway `image1336`, AWS Lambda `image35`, Amazon DynamoDB `image622`, Amazon EventBridge `image304`, Amazon Bedrock `image425`, Amazon S3 `image1614`, Amazon CloudFront `image1222`, Amazon CloudWatch `image974`, AWS X-Ray `image730`, AWS CloudFormation `image1000`, AWS Cloud group tab `image10`, Users `image16`. Re-derive from the yaml if the deck version changes; do not trust these numbers across deck updates.

Gotchas:
- The **Users** glyph is dark gray for light backgrounds. On a dark page recolor every non transparent pixel to a light tint (`(214,224,240)`), keeping alpha.
- Keep the **AWS Cloud** tab icon (`image10`) unmodified. It is a dark tile with the aws logo and matches the reference style. Recoloring it turns it into a blank white square.
- IcePanel's public icon CDN is a fallback only. It lacks Bedrock.

## Layout method

Canvas: SVG `viewBox` about 1780 wide, scales to the page with `width: 100%`.

- **Cards**: 156 x 124 (half width 78, half height 62), rounded, subtle gradient, 52px icon on top, bold title (14px) and 1 or 2 muted subtitle lines (12px). Keep titles under about 22 characters.
- **Grid**: columns about 320px apart so a labelled connector fits between cards (the label needs about 100 to 150px of clear line). Rows about 190px apart. Put the data flow left to right and top to bottom, with hosting (CDN and static site) on the top row, request path in the middle, async workflow and storage below.
- **Ports**: connectors start and end on the card edge midpoints (left, right, top, bottom). When two connectors use the same side, offset them (for example y minus 14 and y plus 14) so each has its own port.
- **Routing recipe**: leave the source port, run to a private lane (a unique x or y not used by another connector), turn once or twice, arrive at the target port. Branches from one node use separate ports and diverge in opposite directions. Keep at least 24px between parallel connectors. Long runs go along the outer edge lanes, never through the middle of the grid.
- **Frame**: draw the AWS Cloud (and Region) frame with its title tab. Reserve a 60px header band above the first row so the title is never hidden under a card. Browser or on premises actors sit outside the frame; connectors may cross the frame border.
- **Labels**: 12px semibold, drawn with a dark halo (`paint-order: stroke`) so they stay readable; place them just above a horizontal segment or beside a vertical one. Verb phrases or API names ("PutEvents: ClaimSubmitted", "Converse", "presigned POST"). Never put a label on a connector it does not describe.
- **Badges**: 24px orange circles with step numbers sitting on the connector they describe, matching a numbered "How it flows" list below the diagram (one sentence per step, include the failure path and the policy thresholds if relevant).
- **Arrowheads**: one marker, same color as the line.

## Page chrome

Match the project's brand (the re:Imburse example uses navy `#0a1020`, card `#121b30`, border `#2a3a5e`, orange `#ff9900`, a violet to orange gradient ribbon with the event and session code). Include: ribbon, `h1`, one paragraph summary, diagram panel, "How a claim flows" panel, "Observability and deployment" panel (X-Ray, CloudWatch, SAM or CloudFormation with a one line description each), footer crediting the AWS Architecture Icons. Add `<title>` and `<desc>` to the SVG, and make text contrast at least 4.5:1.

## Workflow

1. Read the project: `template.yaml`, CDK, or Terraform, plus the handlers, to list the real services and the real data flow. Do not invent services.
2. Draw the grid on paper first: node coordinates, then each connector path, then labels and badges.
3. Copy `references/make-diagram-example.py` to `<project>/scripts/make-diagram.py`; replace `NODES`, `EDGES`, `LABELS`, `BADGES`, `STEPS` and the page copy.
4. Run `python3 scripts/make-diagram.py`. Fix every message from `check_layout()` (the label width estimate is conservative, so shift or shorten a label rather than disabling the check).
5. Render and inspect:
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --hide-scrollbars \
     --window-size=1800,1100 --screenshot=.tmp-shots/<new-name>.png "file://$PWD/docs/architecture.html"
   ```
   `read_file` returns a cached image for a path it has already read, so always use a **new file name** for each re-render, and retry once if the first read right after `cp` or the screenshot reports ENOENT. Delete `.tmp-shots/` when done.
6. `open docs/architecture.html` for the user. Append a round to the project's `CHANGES.md`.

## Quality bar (check before delivering)

- Zero crossing or overlapping connectors, zero connectors through cards (checker passes, screenshot agrees).
- Every card uses an official icon; every connector has a direction arrow and, where meaningful, a label.
- Every badge number appears in the flow list and vice versa.
- Frame title, labels and badges are not covered by any card.
- The narrative matches the code (thresholds, retry behavior, DLQ or layer decisions), not a generic design.
