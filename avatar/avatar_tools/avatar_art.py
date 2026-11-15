#!/usr/bin/env python3
"""Generates the sample avatar art in avatar/assets/ (_ui/ holds the chrome).

Every layer is drawn as SVG on one shared 512x768 canvas, so a dropped-in
item lines up with the body without any offset data.  Run it after editing a
drawing, or as a reference for making art by hand:

    python tools/gen_art.py

Output is PNG at 2x (1024x1536) so it stays sharp on hi-dpi screens.
"""
import os
import sys
from pathlib import Path

from PySide6.QtCore import QRectF, Qt
from PySide6.QtGui import QColor, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer

W, H = 512, 768
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ASSETS = os.path.join(ROOT, "assets")
UI = os.path.join(ROOT, "assets", "_ui")

SKIN = {
    "pale": ("#f4d3bd", "#e0b89f"),
    "light": ("#efc3a2", "#d9a381"),
    "tan": ("#d99a6c", "#be7f54"),
    "brown": ("#a86a42", "#8d5533"),
    "deep": ("#6f4229", "#5a3420"),
    "olive": ("#c08f5e", "#a57546"),
    "amber": ("#8d5433", "#74401f"),
    "mahogany": ("#5a3320", "#472417"),
}


def svg(body, w=W, h=H):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {W} {H}">{body}</svg>'
    )


# ---------------------------------------------------------------- body parts


def body_svg(skin, shade):
    """Head, torso, arms, legs, feet and a simple face."""
    return svg(f"""
  <g>
    <path d="M226,430 L224,626" stroke="{skin}" stroke-width="56" stroke-linecap="round"/>
    <path d="M286,430 L288,626" stroke="{skin}" stroke-width="56" stroke-linecap="round"/>
    <ellipse cx="219" cy="645" rx="31" ry="20" fill="{skin}"/>
    <ellipse cx="293" cy="645" rx="31" ry="20" fill="{skin}"/>
    <rect x="192" y="392" width="128" height="88" rx="32" fill="{skin}"/>
    <path d="M256,236 C300,236 322,242 334,260 C344,278 345,300 341,330 L330,424
             C328,436 320,442 308,442 L204,442 C192,442 184,436 182,424 L171,330
             C167,300 168,278 178,260 C190,242 212,236 256,236 Z" fill="{skin}"/>
    <rect x="234" y="198" width="44" height="50" rx="18" fill="{shade}"/>
    <path d="M186,286 L166,404" stroke="{skin}" stroke-width="46" stroke-linecap="round"/>
    <path d="M326,286 L346,404" stroke="{skin}" stroke-width="46" stroke-linecap="round"/>
    <circle cx="163" cy="412" r="24" fill="{skin}"/>
    <circle cx="349" cy="412" r="24" fill="{skin}"/>
    <circle cx="186" cy="152" r="15" fill="{skin}"/>
    <circle cx="326" cy="152" r="15" fill="{skin}"/>
    <ellipse cx="256" cy="146" rx="76" ry="82" fill="{skin}"/>
    <ellipse cx="230" cy="150" rx="8" ry="10" fill="#2c2319"/>
    <ellipse cx="282" cy="150" rx="8" ry="10" fill="#2c2319"/>
    <path d="M218,130 Q230,123 243,129" stroke="#3d2b1c" stroke-width="5"
          stroke-linecap="round" fill="none"/>
    <path d="M269,129 Q282,123 294,130" stroke="#3d2b1c" stroke-width="5"
          stroke-linecap="round" fill="none"/>
    <path d="M255,158 Q250,172 258,175" stroke="{shade}" stroke-width="4"
          stroke-linecap="round" fill="none"/>
    <path d="M243,190 Q256,199 269,190" stroke="#96503c" stroke-width="5"
          stroke-linecap="round" fill="none"/>
  </g>""")


def hair_svg(style, colour):
    if style == "short":
        d = ("M256,56 C312,56 340,96 338,152 C330,128 322,118 314,112 "
             "C300,134 212,134 198,112 C190,118 182,128 174,152 "
             "C172,96 200,56 256,56 Z")
        extra = ""
    elif style == "spiky":
        d = ("M256,54 C312,54 340,96 338,152 C330,128 322,118 314,112 "
             "C300,134 212,134 198,112 C190,118 182,128 174,152 "
             "C172,96 200,54 256,54 Z")
        extra = (f'<path d="M188,96 L200,40 L226,86 L246,26 L268,84 L292,34 '
                 f'L308,86 L326,48 L332,100 Z" fill="{colour}"/>')
    elif style == "long":
        d = ("M256,56 C312,56 340,96 338,152 C330,128 322,118 314,112 "
             "C300,134 212,134 198,112 C190,118 182,128 174,152 "
             "C172,96 200,56 256,56 Z")
        extra = (f'<path d="M174,120 C160,196 164,268 152,330 L206,330 '
                 f'C198,268 196,196 196,132 Z" fill="{colour}"/>'
                 f'<path d="M338,120 C352,196 348,268 360,330 L306,330 '
                 f'C314,268 316,196 316,132 Z" fill="{colour}"/>')
    else:  # bun
        d = ("M256,64 C312,64 340,100 338,152 C330,128 322,118 314,112 "
             "C300,134 212,134 198,112 C190,118 182,128 174,152 "
             "C172,100 200,64 256,64 Z")
        extra = f'<circle cx="256" cy="52" r="30" fill="{colour}"/>'
    return svg(f'<path d="{d}" fill="{colour}"/>{extra}')


TORSO = ("M256,232 C302,232 326,238 338,258 C350,278 351,302 347,334 L336,436 "
         "C334,449 325,455 312,455 L200,455 C187,455 178,449 176,436 L165,334 "
         "C161,302 162,278 174,258 C186,238 210,232 256,232 Z")


def shirt_svg(kind, colour, dark):
    if kind == "tee":
        sleeves = (f'<path d="M184,288 L172,338" stroke="{colour}" stroke-width="54" '
                   f'stroke-linecap="round"/>'
                   f'<path d="M328,288 L340,338" stroke="{colour}" stroke-width="54" '
                   f'stroke-linecap="round"/>')
        detail = f'<path d="M232,236 Q256,252 280,236" fill="none" stroke="{dark}" stroke-width="7"/>'
    elif kind == "hoodie":
        sleeves = (f'<path d="M184,292 L170,400" stroke="{colour}" stroke-width="56" '
                   f'stroke-linecap="round"/>'
                   f'<path d="M328,292 L342,400" stroke="{colour}" stroke-width="56" '
                   f'stroke-linecap="round"/>')
        detail = (f'<ellipse cx="256" cy="244" rx="62" ry="26" fill="{dark}"/>'
                  f'<rect x="214" y="352" width="84" height="52" rx="14" fill="{dark}"/>'
                  f'<path d="M246,262 L246,300 M266,262 L266,300" stroke="{dark}" '
                  f'stroke-width="5"/>')
    elif kind == "jersey":
        sleeves = (f'<path d="M184,288 L172,332" stroke="{colour}" stroke-width="54" '
                   f'stroke-linecap="round"/>'
                   f'<path d="M328,288 L340,332" stroke="{colour}" stroke-width="54" '
                   f'stroke-linecap="round"/>')
        detail = (f'<path d="M196,252 L316,252" stroke="{dark}" stroke-width="9"/>'
                  f'<path d="M204,300 L308,300 M204,320 L308,320" stroke="#ffffff" '
                  f'stroke-width="8" stroke-linecap="round"/>')
    elif kind == "tank":
        sleeves = ""
        detail = (f'<path d="M212,238 C220,270 232,280 256,280 C280,280 292,270 300,238" '
                  f'fill="none" stroke="{dark}" stroke-width="7"/>')
    else:  # coat
        sleeves = (f'<path d="M184,292 L168,430" stroke="{colour}" stroke-width="58" '
                   f'stroke-linecap="round"/>'
                   f'<path d="M328,292 L344,430" stroke="{colour}" stroke-width="58" '
                   f'stroke-linecap="round"/>')
        detail = (f'<path d="M256,240 L256,510" stroke="{dark}" stroke-width="7"/>'
                  f'<circle cx="268" cy="300" r="7" fill="{dark}"/>'
                  f'<circle cx="268" cy="372" r="7" fill="{dark}"/>')
    bottom = 500 if kind == "coat" else 455
    torso = ("M256,232 C302,232 326,238 338,258 C350,278 351,302 347,334 L336,436 "
             f"C334,{bottom-6} 325,{bottom} 312,{bottom} L200,{bottom} "
             f"C187,{bottom} 178,{bottom-6} 176,436 L165,334 "
             "C161,302 162,278 174,258 C186,238 210,232 256,232 Z")
    return svg(f'{sleeves}<path d="{torso}" fill="{colour}"/>{detail}')


def pants_svg(kind, colour, dark):
    if kind == "shorts":
        legs = (f'<path d="M224,432 L222,516" stroke="{colour}" stroke-width="62" '
                f'stroke-linecap="round"/>'
                f'<path d="M288,432 L290,516" stroke="{colour}" stroke-width="62" '
                f'stroke-linecap="round"/>')
    else:
        legs = (f'<path d="M226,432 L224,614" stroke="{colour}" stroke-width="62" '
                f'stroke-linecap="round"/>'
                f'<path d="M286,432 L288,614" stroke="{colour}" stroke-width="62" '
                f'stroke-linecap="round"/>')
    detail = f'<rect x="192" y="386" width="128" height="18" rx="9" fill="{dark}"/>'
    if kind == "cargo":
        detail += (f'<rect x="196" y="470" width="46" height="54" rx="10" fill="{dark}"/>'
                   f'<rect x="270" y="470" width="46" height="54" rx="10" fill="{dark}"/>')
    if kind == "jeans":
        detail += (f'<path d="M226,440 L224,470" stroke="{dark}" stroke-width="5"/>'
                   f'<path d="M286,440 L288,470" stroke="{dark}" stroke-width="5"/>')
    return svg(f'{legs}<rect x="192" y="392" width="128" height="80" rx="30" '
               f'fill="{colour}"/>{detail}')


def shoes_svg(kind, colour, dark):
    if kind == "boots":
        shoe = ('<path d="M188,604 C188,588 200,582 214,586 L240,600 '
                'C250,606 254,616 252,628 L250,660 C250,668 242,674 232,674 '
                'L200,674 C192,674 186,668 186,660 Z" fill="COL"/>'
                '<rect x="184" y="652" width="70" height="20" rx="8" fill="DARK"/>')
    else:
        shoe = ('<path d="M188,630 C188,616 200,610 214,616 L240,632 '
                'C249,637 253,646 251,656 L250,660 C250,668 242,674 232,674 '
                'L200,674 C192,674 186,668 186,660 Z" fill="COL"/>'
                '<rect x="184" y="658" width="70" height="16" rx="8" fill="DARK"/>')
    shoe = shoe.replace("COL", colour).replace("DARK", dark)
    return svg(shoe + f'<g transform="translate(512,0) scale(-1,1)">{shoe}</g>')


def hat_svg(kind, colour, dark):
    if kind == "cap":
        return svg(f'<path d="M178,134 C180,80 212,50 256,50 C300,50 332,80 334,134 '
                   f'L334,146 L178,146 Z" fill="{colour}"/>'
                   f'<path d="M332,128 C372,132 392,142 392,152 L332,156 Z" fill="{dark}"/>'
                   f'<circle cx="256" cy="52" r="9" fill="{dark}"/>')
    return svg(f'<path d="M184,140 C186,84 216,52 256,52 C296,52 326,84 328,140 Z" '
               f'fill="{colour}"/>'
               f'<rect x="180" y="132" width="152" height="20" rx="10" fill="{dark}"/>'
               f'<circle cx="256" cy="46" r="15" fill="{dark}"/>')


def glasses_svg(kind, colour="#20242b"):
    if kind == "shades":
        return svg(f'<rect x="196" y="134" width="54" height="34" rx="10" fill="{colour}"/>'
                   f'<rect x="262" y="134" width="54" height="34" rx="10" fill="{colour}"/>'
                   f'<path d="M250,146 L262,146" stroke="{colour}" stroke-width="7"/>'
                   f'<path d="M196,146 L182,150 M316,146 L330,150" stroke="{colour}" '
                   'stroke-width="6" stroke-linecap="round"/>')
    return svg(f'<rect x="194" y="130" width="56" height="38" rx="18" fill="none" '
               f'stroke="{colour}" stroke-width="6"/>'
               f'<rect x="262" y="130" width="56" height="38" rx="18" fill="none" '
               f'stroke="{colour}" stroke-width="6"/>'
               f'<path d="M248,148 L264,148" stroke="{colour}" stroke-width="6"/>'
               f'<path d="M198,146 L184,150 M314,146 L328,150" stroke="{colour}" '
               'stroke-width="5" stroke-linecap="round"/>')


def facial_svg(kind, colour):
    if kind == "beard":
        return svg(f'<path d="M190,170 C190,216 216,244 256,244 C296,244 322,216 322,170 '
                   f'C322,188 300,202 256,202 C212,202 190,188 190,170 Z" fill="{colour}"/>')
    return svg(f'<path d="M226,178 Q244,168 256,178 Q268,168 286,178" fill="none" '
               f'stroke="{colour}" stroke-width="12" stroke-linecap="round"/>')


# ---------------------------------------------------------------- renderer


def render(svg_text, out_path, w=W, h=H, scale=2):
    r = QSvgRenderer(svg_text.encode("utf-8"))
    img = QImage(int(w * scale), int(h * scale), QImage.Format_ARGB32_Premultiplied)
    img.fill(Qt.transparent)
    p = QPainter(img)
    p.setRenderHints(QPainter.Antialiasing | QPainter.SmoothPixmapTransform)
    r.render(p, QRectF(0, 0, img.width(), img.height()))
    p.end()
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    if not img.save(out_path):
        raise SystemExit("could not write " + out_path)
    return out_path


ZOOM = 1.18


def zoomed(svg_text, s=ZOOM):
    """Scales the drawing about the canvas centre so the figure fills it."""
    head, rest = svg_text.split(">", 1)
    body = rest[:rest.rindex("</svg>")]
    return (head + "><g transform=\"translate(256,384) scale(%s) translate(-256,-384)\">" % s
            + body + "</g></svg>")


def add(folder, name, svg_text):
    return render(zoomed(svg_text), os.path.join(ASSETS, folder, name + ".png"))


# ---------------------------------------------------------------- background


def background():
    bg = f"""
    <defs>
      <linearGradient id="sky" x1="0" y1="0" x2="0.15" y2="1">
        <stop offset="0" stop-color="#7fae1e"/>
        <stop offset="0.35" stop-color="#5c8c14"/>
        <stop offset="0.72" stop-color="#2f4a0b"/>
        <stop offset="1" stop-color="#101a05"/>
      </linearGradient>
      <radialGradient id="glow" cx="0.5" cy="0.42" r="0.62">
        <stop offset="0" stop-color="#ffffff" stop-opacity="0.20"/>
        <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="floor" cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stop-color="#0d1404" stop-opacity="0.85"/>
        <stop offset="0.7" stop-color="#0d1404" stop-opacity="0.35"/>
        <stop offset="1" stop-color="#0d1404" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect width="1920" height="1080" fill="url(#sky)"/>
    <ellipse cx="960" cy="470" rx="820" ry="520" fill="url(#glow)"/>
    """
    # bokeh
    import random

    random.seed(7)
    for i in range(46):
        cx = random.uniform(-40, 1960)
        cy = random.uniform(-40, 1080)
        r = random.uniform(14, 118)
        op = random.uniform(0.03, 0.16)
        bg += (f'<circle cx="{cx:.0f}" cy="{cy:.0f}" r="{r:.0f}" fill="#ffffff" '
               f'opacity="{op:.3f}"/>')
    for i in range(9):
        cx = random.uniform(0, 1920)
        cy = random.uniform(20, 620)
        r = random.uniform(70, 210)
        bg += (f'<circle cx="{cx:.0f}" cy="{cy:.0f}" r="{r:.0f}" fill="none" '
               f'stroke="#ffffff" stroke-width="2" opacity="0.06"/>')
    bg += '<ellipse cx="960" cy="1010" rx="900" ry="230" fill="url(#floor)"/>'
    text = ('<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" '
            'viewBox="0 0 1920 1080">' + bg + "</svg>")
    render(text, os.path.join(UI, "background.png"), 1920, 1080, scale=1)


def shadow():
    doc = ('<svg xmlns="http://www.w3.org/2000/svg" width="960" height="280" '
           'viewBox="0 0 960 280">'
           '<defs><radialGradient id="s">'
           '<stop offset="0" stop-color="#000000" stop-opacity="0.55"/>'
           '<stop offset="0.55" stop-color="#000000" stop-opacity="0.24"/>'
           '<stop offset="1" stop-color="#000000" stop-opacity="0"/>'
           '</radialGradient></defs>'
           '<ellipse cx="480" cy="140" rx="470" ry="130" fill="url(#s)"/></svg>')
    render(doc, os.path.join(UI, "shadow.png"), 960, 280, scale=1)


def main():
    for name, (skin, shade) in SKIN.items():
        add("10_body", "body_" + name, body_svg(skin, shade))

    # Hair: four shapes, five colours each. The original four names stay put so a
    # saved avatar keeps resolving.
    hair_colours = {
        "brown": "#4a3324",
        "black": "#23201e",
        "blond": "#c9963f",
        "red": "#8c3b23",
        "grey": "#8d8d93",
    }
    for style in ("short", "spiky", "long", "bun"):
        for tone, colour in hair_colours.items():
            add("50_hair", "hair_%s_%s" % (style, tone), hair_svg(style, colour))

    shirts = [
        ("tee",    "blue",  "#2f7fd4", "#1f5c9e"),
        ("tee",    "white", "#eef1f4", "#c9ced6"),
        ("tee",    "red",   "#c5443a", "#8f2c25"),
        ("tee",    "black", "#2b2f36", "#1d2026"),
        ("hoodie", "grey",  "#5c6470", "#464d57"),
        ("hoodie", "navy",  "#2b3550", "#1d2438"),
        ("hoodie", "olive", "#6b7048", "#4f5333"),
        ("hoodie", "plum",  "#5a3355", "#3f2139"),
        ("jersey", "green", "#3fa34d", "#2b7a37"),
        ("jersey", "red",   "#bf3b39", "#8a2724"),
        ("jersey", "blue",  "#2f5fa8", "#204278"),
        ("jersey", "white", "#eef1f4", "#c9ced6"),
        ("tank",   "white", "#eef1f4", "#c9ced6"),
        ("tank",   "black", "#2b2f36", "#1d2026"),
        ("tank",   "blue",  "#2f7fd4", "#1f5c9e"),
        ("tank",   "pink",  "#d0708f", "#a44f6b"),
        ("coat",   "navy",  "#2b3550", "#1d2438"),
        ("coat",   "grey",  "#5c6470", "#464d57"),
        ("coat",   "brown", "#6d4630", "#4a2d1e"),
        ("coat",   "olive", "#6b7048", "#4f5333"),
    ]
    for kind, name, colour, dark in shirts:
        add("40_shirt", "%s_%s" % (kind, name), shirt_svg(kind, colour, dark))

    pants = [
        ("jeans",  "indigo", "#3f5b8b", "#2f4569"),
        ("jeans",  "black",  "#2b2f36", "#1d2026"),
        ("jeans",  "grey",   "#5c6470", "#464d57"),
        ("joggers", "black", "#2b2f36", "#1d2026"),
        ("joggers", "grey",  "#5c6470", "#464d57"),
        ("joggers", "navy",  "#2b3550", "#1d2438"),
        ("shorts", "khaki",  "#b99a63", "#8f7546"),
        ("shorts", "black",  "#2b2f36", "#1d2026"),
        ("shorts", "denim",  "#3f5b8b", "#2f4569"),
        ("cargo",  "olive",  "#6b7048", "#4f5333"),
        ("cargo",  "brown",  "#6d4630", "#4a2d1e"),
        ("cargo",  "grey",   "#5c6470", "#464d57"),
    ]
    for kind, name, colour, dark in pants:
        add("20_pants", "%s_%s" % (kind, name), pants_svg(kind, colour, dark))

    shoes = [
        ("sneakers", "white", "#e9edf1", "#b9c2cc"),
        ("sneakers", "black", "#2b2f36", "#1d2026"),
        ("sneakers", "navy",  "#2b3550", "#1d2438"),
        ("sneakers", "red",   "#c5443a", "#8f2c25"),  # shipped as trainers_red
        ("sneakers", "green", "#3fa34d", "#2b7a37"),
        ("boots",    "brown", "#6d4630", "#4a2d1e"),
        ("boots",    "black", "#2b2f36", "#1d2026"),
        ("boots",    "tan",   "#b08150", "#8a6238"),
    ]
    for kind, name, colour, dark in shoes:
        shipped = {("sneakers", "red"): "trainers_red"}
        add("30_shoes", shipped.get((kind, name), "%s_%s" % (kind, name)),
            shoes_svg(kind, colour, dark))

    hats = [
        ("cap",    "blue",  "#2f6fd0", "#1f4f9c"),
        ("cap",    "red",   "#c5443a", "#8f2c25"),
        ("cap",    "black", "#2b2f36", "#1d2026"),
        ("cap",    "sand",  "#c9a882", "#a0825f"),
        ("beanie", "grey",  "#6c7480", "#4d545e"),
        ("beanie", "navy",  "#2b3550", "#1d2438"),
        ("beanie", "red",   "#a83a33", "#82251f"),
        ("beanie", "white", "#e9edf1", "#b9c2cc"),
    ]
    for kind, name, colour, dark in hats:
        add("60_hat", "%s_%s" % (kind, name), hat_svg(kind, colour, dark))

    glasses = [
        ("round",  "black", "#2b2b2b"),
        ("round",  "gold",  "#b98b3c"),
        ("round",  "blue",  "#2f5fa8"),
        ("shades", "black", "#20242b"),
        ("shades", "blue",  "#1d2f4d"),
        ("shades", "red",   "#5a1f1c"),
    ]
    # Names shipped by the first catalogue are kept, so an avatar saved before
    # this expansion still finds its glasses.
    for kind, name, colour in glasses:
        shipped = {"round_black": "glasses_round", "shades_black": "shades_dark"}
        add("70_glasses", shipped.get("%s_%s" % (kind, name), "%s_%s" % (kind, name)),
            glasses_svg(kind, colour))

    facial = [
        ("beard",    "brown", "#4a3324"),
        ("beard",    "black", "#23201e"),
        ("beard",    "grey",  "#8d8d93"),
        ("mustache", "brown", "#4a3324"),
        ("mustache", "black", "#23201e"),
        ("mustache", "grey",  "#8d8d93"),
    ]
    for kind, name, colour in facial:
        add("45_facial-hair", "%s_%s" % (kind, name), facial_svg(kind, colour))

    background()
    shadow()

    count = sum(len(f) for _, _, f in os.walk(ASSETS))
    print(f"wrote {count} images under {ASSETS} (items and _ui/)")

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from art_index import write_index
    write_index()


if __name__ == "__main__":
    main()
