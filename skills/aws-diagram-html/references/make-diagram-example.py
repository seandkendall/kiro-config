"""Worked example for the aws-diagram-html skill (the re:Imburse diagram, verified end to end).

To reuse: copy this file to <project>/scripts/make-diagram.py, then replace NODES, EDGES, LABELS,
BADGES and STEPS and the page copy in build(). Keep check_layout(): it fails the run on any crossing
edge or collision. ROOT assumes the file lives in <project>/scripts/.

Generates docs/architecture.html: a self-contained architecture diagram with official AWS icons.

Icons come from the AWS Architecture Icons deck that `awsdac` caches in ~/.cache/awsdac.
Edges are hand-routed orthogonal paths on a grid so that no two lines cross or overlap.
"""

from __future__ import annotations

import base64
import glob
import io
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MEDIA = Path(glob.glob(str(Path.home() / ".cache/awsdac/*Light-BG*.pptx/ppt/media"))[0])

ICONS = {
    "users": "image16.png",
    "cloudfront": "image1222.png",
    "s3": "image1614.png",
    "apigw": "image1336.png",
    "lambda": "image35.png",
    "ddb": "image622.png",
    "eventbridge": "image304.png",
    "bedrock": "image425.png",
    "cloudwatch": "image974.png",
    "xray": "image730.png",
    "cfn": "image1000.png",
    "cloud": "image10.png",
}


def icon_data(key: str) -> str:
    """Return a base64 PNG data URI for an icon, recoloring the dark user glyph for the dark theme."""
    image = Image.open(MEDIA / ICONS[key]).convert("RGBA")
    if key == "users":
        pixels = image.load()
        for y in range(image.height):
            for x in range(image.width):
                r, g, b, a = pixels[x, y]
                if a:
                    pixels[x, y] = (214, 224, 240, a)
    image = image.resize((160, 160), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buffer.getvalue()).decode()


HW, HH = 78, 62  # card half width and half height

NODES = [
    # key, icon, cx, cy, title, subtitle lines
    ("users", "users", 100, 425, "Browser", ["Alex (Employee)", "Jordan (Manager)"]),
    ("cf", "cloudfront", 380, 150, "Amazon CloudFront", ["Serves the React app"]),
    ("site", "s3", 700, 150, "Amazon S3", ["Static site bucket"]),
    ("apigw", "apigw", 380, 425, "Amazon API Gateway", ["REST API, X-Ray on"]),
    ("submit", "lambda", 700, 330, "Submit Lambda", ["Save claim, emit event"]),
    ("api", "lambda", 700, 520, "API handlers", ["Upload, list, decide"]),
    ("ddb", "ddb", 1020, 425, "Amazon DynamoDB", ["Claims table"]),
    ("eb", "eventbridge", 1320, 330, "Amazon EventBridge", ["Default bus and rule"]),
    ("flow", "lambda", 1320, 520, "Approval workflow", ["Lambda durable function"]),
    ("nova", "bedrock", 1620, 520, "Amazon Bedrock", ["Nova, Converse API"]),
    ("receipts", "s3", 700, 740, "Amazon S3", ["Receipts bucket"]),
]

# Orthogonal edges, routed by hand. (path, dashed)
EDGES = [
    "M100,363 V150 H302",  # users -> CloudFront
    "M458,150 H622",  # CloudFront -> site bucket
    "M178,425 H302",  # users -> API Gateway
    "M458,411 H540 V330 H622",  # API Gateway -> Submit
    "M458,439 H540 V520 H622",  # API Gateway -> API handlers
    "M778,330 H1020 V363",  # Submit -> DynamoDB
    "M700,268 V230 H1320 V268",  # Submit -> EventBridge
    "M778,506 H1020 V487",  # API handlers -> DynamoDB
    "M778,534 H1242",  # API handlers -> workflow (callback)
    "M1320,392 V458",  # EventBridge -> workflow
    "M1242,506 H1130 V425 H1098",  # workflow -> DynamoDB
    "M1398,520 H1542",  # workflow -> Bedrock
    "M1320,582 V740 H778",  # workflow <- receipts
    "M700,582 V678",  # API handlers -> receipts (presign)
    "M100,487 V740 H622",  # users -> receipts (direct upload)
]

# (x, y, text, anchor)
LABELS = [
    (255, 138, "load app", "middle"),
    (540, 138, "origin access", "middle"),
    (240, 413, "HTTPS", "middle"),
    (572, 318, "POST /claims", "middle"),
    (900, 318, "save claim", "middle"),
    (1010, 220, "PutEvents: ClaimSubmitted", "middle"),
    (880, 496, "read/write claims", "middle"),
    (1060, 556, "SendDurableExecutionCallback", "middle"),
    (1146, 474, "update claim", "start"),
    (1336, 429, "rule: ClaimSubmitted", "start"),
    (1470, 504, "Converse", "middle"),
    (1010, 728, "GetObject", "middle"),
    (712, 636, "presigned URLs", "start"),
    (371, 728, "presigned POST, direct upload", "middle"),
]

BADGES = [
    (1, 262, 740),
    (2, 540, 372),
    (3, 880, 230),
    (4, 1320, 425),
    (5, 1424, 520),
    (6, 1130, 466),
    (7, 880, 534),
    (8, 540, 480),
]

STEPS = [
    "Alex picks one or more receipts. Each file uploads straight to S3 with a presigned POST.",
    "The Submit Lambda checks the file and saves a PROCESSING claim to DynamoDB.",
    "Submit publishes a ClaimSubmitted event to the default EventBridge bus.",
    "An EventBridge rule starts the approval workflow, a Lambda durable function.",
    "The workflow loads the receipt from S3 and asks Nova (Converse) for merchant, date, total and confidence. No retry: an unreadable receipt marks the claim FAILED with the error.",
    "Confidence of 90% or more and a total of $50 or less auto-approves. Otherwise the claim is saved as PENDING_REVIEW and the workflow waits on a callback.",
    "Jordan approves or rejects in the UI. The API handler records it and sends the durable callback, so the workflow resumes and finishes.",
    "The UI polls the API every 4 seconds. The API handlers read DynamoDB and presign S3 links for thumbnails and the receipt viewer.",
]



# --------------------------------------------------------------------------------------------
# Layout checker: fails the build if any edge crosses, touches or overlaps another edge, passes
# through a card, or if a label or badge collides with a card, another label, or an edge.
# --------------------------------------------------------------------------------------------

Rect = tuple[float, float, float, float]  # x1, y1, x2, y2


def parse_path(d: str) -> list[Rect]:
    """Turn an orthogonal path (M, H, V commands) into axis-aligned segment rectangles."""
    tokens = re.findall(r"[MHV]|-?\d+(?:\.\d+)?", d)
    segments: list[Rect] = []
    x = y = 0.0
    i = 0
    while i < len(tokens):
        cmd = tokens[i]
        if cmd == "M":
            x, y = float(tokens[i + 1]), float(tokens[i + 2])
            i += 3
        elif cmd == "H":
            value = float(tokens[i + 1])
            segments.append((min(x, value), y, max(x, value), y))
            x = value
            i += 2
        elif cmd == "V":
            value = float(tokens[i + 1])
            segments.append((x, min(y, value), x, max(y, value)))
            y = value
            i += 2
        else:
            raise ValueError(f"Unsupported path command {cmd!r}; use only M, H, V")
    return segments


def overlaps(a: Rect, b: Rect, pad: float = 0.0) -> bool:
    return not (a[2] + pad < b[0] or b[2] + pad < a[0] or a[3] + pad < b[1] or b[3] + pad < a[1])


def check_layout() -> list[str]:
    """Return a list of human-readable layout problems (empty means the diagram is clean)."""
    problems: list[str] = []
    cards = {k: (cx - HW, cy - HH, cx + HW, cy + HH) for k, _i, cx, cy, _t, _s in NODES}
    edges = [parse_path(d) for d in EDGES]

    for i, segs in enumerate(edges):
        for seg in segs:
            for name, rect in cards.items():
                inner = (rect[0] + 3, rect[1] + 3, rect[2] - 3, rect[3] - 3)
                if overlaps(seg, inner):
                    problems.append(f"edge {i} ({EDGES[i]}) passes through card {name}")
    for i in range(len(edges)):
        for j in range(i + 1, len(edges)):
            if any(overlaps(a, b, pad=1.5) for a in edges[i] for b in edges[j]):
                problems.append(f"edge {i} and edge {j} cross, touch or overlap")

    boxes: list[tuple[str, Rect]] = []
    for x, y, text, anchor in LABELS:
        width = len(text) * 6.4 + 6
        left = x - width / 2 if anchor == "middle" else x
        boxes.append((f"label {text!r}", (left, y - 12, left + width, y + 4)))
    for n, x, y in BADGES:
        boxes.append((f"badge {n}", (x - 13, y - 13, x + 13, y + 13)))
    for name, box in boxes:
        for card, rect in cards.items():
            if overlaps(box, rect):
                problems.append(f"{name} collides with card {card}")
        if name.startswith("label"):
            for i, segs in enumerate(edges):
                if any(overlaps(box, seg) for seg in segs):
                    problems.append(f"{name} sits on edge {i}")
    for a in range(len(boxes)):
        for b in range(a + 1, len(boxes)):
            if overlaps(boxes[a][1], boxes[b][1]):
                problems.append(f"{boxes[a][0]} overlaps {boxes[b][0]}")
    return problems


def card(
    key: str,
    icon: str,
    cx: int,
    cy: int,
    title: str,
    sub: list[str],
    uris: dict[str, str],
) -> str:
    x, y = cx - HW, cy - HH
    parts = [
        f'<g data-testid="node-{key}">',
        f'<rect x="{x}" y="{y}" width="{HW * 2}" height="{HH * 2}" rx="14" fill="url(#card)" stroke="#2a3a5e" stroke-width="1.5"/>',
        f'<image href="{uris[icon]}" x="{cx - 26}" y="{y + 10}" width="52" height="52"/>',
        f'<text x="{cx}" y="{y + 82}" text-anchor="middle" class="t">{title}</text>',
    ]
    for i, line in enumerate(sub):
        parts.append(
            f'<text x="{cx}" y="{y + 99 + i * 14}" text-anchor="middle" class="s">{line}</text>'
        )
    parts.append("</g>")
    return "\n".join(parts)


def build() -> str:
    uris = {k: icon_data(k) for k in ICONS}
    edges = "\n".join(
        f'<path d="{d}" class="edge" marker-end="url(#arrow)"/>' for d in EDGES
    )
    cards = "\n".join(card(k, i, cx, cy, t, s, uris) for k, i, cx, cy, t, s in NODES)
    labels = "\n".join(
        f'<text x="{x}" y="{y}" text-anchor="{a}" class="lbl">{t}</text>'
        for x, y, t, a in LABELS
    )
    badges = "\n".join(
        f'<g><circle cx="{x}" cy="{y}" r="12" class="badge"/><text x="{x}" y="{y + 4.5}" text-anchor="middle" class="bn">{n}</text></g>'
        for n, x, y in BADGES
    )
    steps = []
    for i, text in enumerate(STEPS):
        col, row = i % 2, i // 2
        steps.append(
            f'<div class="step"><span class="num">{i + 1}</span><p>{text}</p></div>'
        )
    steps_html = "\n".join(steps)

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>re:Imburse architecture | re:Invent SVS343-R</title>
<style>
  :root {{ color-scheme: dark; --bg:#0a1020; --card:#121b30; --line:#2a3a5e; --muted:#9fb0cc; --orange:#ff9900; }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; min-height:100vh; color:#f1f5f9; font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
    background: radial-gradient(60rem 30rem at 85% -10%, rgba(139,92,246,.22), transparent 60%),
                radial-gradient(50rem 28rem at -10% 0%, rgba(255,153,0,.14), transparent 55%), var(--bg); }}
  .ribbon {{ background: linear-gradient(90deg,#7c3aed,#c026d3,#f97316); text-align:center; padding:6px 12px; font-size:12px; font-weight:800; letter-spacing:.18em; text-transform:uppercase; }}
  header {{ max-width:1780px; margin:0 auto; padding:28px 28px 8px; }}
  h1 {{ margin:0; font-size:clamp(24px,3.2vw,38px); font-weight:900; letter-spacing:-.02em; }}
  h1 span {{ color: var(--orange); }}
  header p {{ margin:6px 0 0; color: var(--muted); max-width:70ch; line-height:1.5; }}
  main {{ max-width:1780px; margin:0 auto; padding:12px 28px 48px; }}
  .panel {{ background: rgba(18,27,48,.78); border:1px solid var(--line); border-radius:18px; padding:14px; box-shadow:0 20px 50px rgba(0,0,0,.35); }}
  svg {{ display:block; width:100%; height:auto; }}
  .t {{ font-size:14px; font-weight:700; fill:#f1f5f9; }}
  .s {{ font-size:12px; fill:#9fb0cc; }}
  .lbl {{ font-size:12px; font-weight:600; fill:#cbd5e1; paint-order:stroke; stroke:#0a1020; stroke-width:5px; stroke-linejoin:round; }}
  .edge {{ fill:none; stroke:#7f93b8; stroke-width:2.2; stroke-linejoin:round; }}
  .badge {{ fill:#ff9900; stroke:#0a1020; stroke-width:2; }}
  .bn {{ font-size:13px; font-weight:800; fill:#111827; }}
  .frame {{ fill:rgba(255,255,255,.015); stroke:#8fa3c8; stroke-width:1.5; }}
  .frame-t {{ font-size:15px; font-weight:700; fill:#e2e8f0; }}
  h2 {{ font-size:18px; margin:0 0 12px; }}
  .grid {{ display:grid; grid-template-columns: repeat(auto-fit, minmax(340px,1fr)); gap:12px 24px; }}
  .step {{ display:flex; gap:12px; align-items:flex-start; }}
  .step p {{ margin:2px 0 0; color:#cbd5e1; line-height:1.5; font-size:14px; }}
  .num {{ flex:none; width:26px; height:26px; border-radius:50%; background:var(--orange); color:#111827; font-weight:800; display:grid; place-items:center; font-size:13px; }}
  .stack {{ display:grid; gap:18px; margin-top:18px; }}
  .obs {{ display:flex; flex-wrap:wrap; gap:22px; align-items:center; }}
  .obs img {{ width:56px; height:56px; border-radius:10px; }}
  .obs .item {{ display:flex; gap:12px; align-items:center; min-width:260px; flex:1; }}
  .obs strong {{ display:block; }}
  .obs span {{ color:var(--muted); font-size:13px; line-height:1.45; }}
  footer {{ text-align:center; color:var(--muted); font-size:12px; padding-bottom:28px; }}
</style>
</head>
<body>
<div class="ribbon">AWS re:Invent 2026 &nbsp;|&nbsp; Session SVS343-R &nbsp;|&nbsp; Architecture</div>
<header>
  <h1>re:<span>Imburse</span> architecture</h1>
  <p>Employees upload receipts, Amazon Nova reads them, and an AWS Lambda durable function either auto-approves the claim or waits for a manager. Numbered steps match the list below the diagram.</p>
</header>
<main>
  <div class="panel">
    <svg viewBox="0 0 1780 850" role="img" aria-labelledby="dt dd">
      <title id="dt">re:Imburse architecture</title>
      <desc id="dd">Browser to CloudFront and S3 for the site, and to API Gateway, Lambda, DynamoDB, EventBridge, a durable approval workflow, Bedrock Nova and an S3 receipts bucket.</desc>
      <defs>
        <linearGradient id="card" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#18233d"/><stop offset="1" stop-color="#101a2f"/></linearGradient>
        <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#7f93b8"/></marker>
      </defs>
      <rect x="210" y="14" width="1536" height="826" rx="18" class="frame"/>
      <image href="{uris["cloud"]}" x="210" y="14" width="44" height="44"/>
      <text x="266" y="43" class="frame-t">AWS Cloud, us-east-1</text>
      {edges}
      {cards}
      {labels}
      {badges}
    </svg>
  </div>

  <div class="stack">
    <section class="panel" aria-labelledby="flow-h">
      <h2 id="flow-h">How a claim flows</h2>
      <div class="grid">
        {steps_html}
      </div>
    </section>

    <section class="panel" aria-labelledby="obs-h">
      <h2 id="obs-h">Observability and deployment</h2>
      <div class="obs">
        <div class="item"><img src="{uris["xray"]}" alt="AWS X-Ray"><div><strong>AWS X-Ray</strong><span>Active tracing on the API Gateway stage and all three Lambdas, with custom subsegments inside each workflow step.</span></div></div>
        <div class="item"><img src="{uris["cloudwatch"]}" alt="Amazon CloudWatch"><div><strong>Amazon CloudWatch</strong><span>Structured JSON logs, API execution and access logs, detailed metrics, and one log line per durable operation.</span></div></div>
        <div class="item"><img src="{uris["cfn"]}" alt="AWS CloudFormation"><div><strong>AWS SAM and CloudFormation</strong><span>Stack reimburse-svs343r. The workflow has no DLQ and there is no shared Lambda layer.</span></div></div>
      </div>
    </section>
  </div>
</main>
<footer>re:Imburse, AWS re:Invent 2026, SVS343-R. Icons: AWS Architecture Icons.</footer>
</body>
</html>
"""


if __name__ == "__main__":
    issues = check_layout()
    if issues:
        raise SystemExit("Layout problems:\n  " + "\n  ".join(issues))
    print("Layout check passed: no crossing edges, no collisions.")
    out = ROOT / "docs" / "architecture.html"
    out.parent.mkdir(exist_ok=True)
    out.write_text(build(), encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")
