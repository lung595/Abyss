#!/usr/bin/env python3
"""Reference wireframes for the Abyss app visual directions (NAK-283).

Not production code: a throwaway renderer that draws the three candidate
directions (A Porthole, B Deck, C Water column) in every state required by
the story, light and dark, from fictional data only. It also prints the
measured WCAG contrast of the app palette tokens (`--table`).
Run: python3 docs/design/app/render.py [outdir]
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/google-noto-vf/NotoSans[wght].ttf"
MONO = "/usr/share/fonts/google-noto-vf/NotoSansMono[wght].ttf"

def font(size, weight=400, mono=False):
    f = ImageFont.truetype(MONO if mono else FONT, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f

# --- App palette tokens: same API as DMS Theme (primitives -> semantic roles) ---
DARK = dict(  # "abyss": the night sea of the widget (#02040b)
    surface="#02040b", surfaceContainerLowest="#000208", surfaceContainerLow="#070a14",
    surfaceContainer="#0c1020", surfaceContainerHigh="#131a2e", surfaceContainerHighest="#1b2440",
    onSurface="#e8ecf6", onSurfaceVariant="#a3acc0", outline="#58648a",
    primary="#6fe3ff", onPrimary="#04202c", secondary="#ffc46b", onSecondary="#2d1b00",
    tertiary="#ff9ad5", success="#7ee2a8", warning="#ffb35c", error="#ff7b86",
    data1="#6fe3ff", data2="#ffc46b", data3="#ff9ad5", data4="#b7a6ff", isLightMode=False)
LIGHT = dict(  # "lagoon": shallow water seen from the surface
    surface="#f3f7fb", surfaceContainerLowest="#ffffff", surfaceContainerLow="#e9f0f6",
    surfaceContainer="#dfe8f0", surfaceContainerHigh="#d2dde8", surfaceContainerHighest="#c4d2df",
    onSurface="#0e1a2b", onSurfaceVariant="#475870", outline="#6f8097",
    primary="#0b6f8f", onPrimary="#ffffff", secondary="#7a4f00", onSecondary="#ffffff",
    tertiary="#a8336f", success="#1e7a4a", warning="#8a5600", error="#b3263a",
    data1="#0b6f8f", data2="#7a4f00", data3="#a8336f", data4="#5b4bb8", isLightMode=True)

def lum(h):
    r, g, b = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def contrast(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

def table():
    pairs = [("onSurface", "surface"), ("onSurface", "surfaceContainerHighest"),
             ("onSurfaceVariant", "surface"), ("onSurfaceVariant", "surfaceContainerHighest"),
             ("outline", "surface"), ("primary", "surface"), ("onPrimary", "primary"),
             ("secondary", "surface"), ("tertiary", "surface"), ("success", "surface"),
             ("warning", "surface"), ("error", "surface"), ("data4", "surface")]
    print("| Paire | Sombre | Clair |")
    print("|---|---|---|")
    for a, b in pairs:
        print(f"| {a} / {b} | {contrast(DARK[a], DARK[b]):.1f}:1 | {contrast(LIGHT[a], LIGHT[b]):.1f}:1 |")

# --- fictional data (value 8) ---
PEERS = [("atlas-server", "ray", 12, True), ("harbor-vps", "whale", 48, True), ("nova-laptop", "fish", 6, True),
         ("reef-nas", "turtle", 20, True), ("kite-phone", "horse", 95, True), ("pi-lantern", "squid", 140, False),
         ("dune-desktop", "nautilus", 9, True), ("orca-build", "ray", 31, False)]
LONG = "a-very-long-device-name-that-never-ends-on-the-workbench-of-the-lab-02"

class Board:
    def __init__(self, w, h, t):
        self.t, self.w, self.h = t, w, h
        self.im = Image.new("RGB", (w, h), t["surface"])
        self.d = ImageDraw.Draw(self.im, "RGBA")
    def rect(self, x, y, w, h, fill=None, outline=None, r=8):
        self.d.rounded_rectangle([x, y, x + w - 1, y + h - 1], r, fill=fill, outline=outline, width=1)
    def text(self, x, y, s, size=13, color=None, weight=400, mono=False, anchor="la"):
        self.d.text((x, y), s, fill=color or self.t["onSurface"], font=font(size, weight, mono), anchor=anchor)
    def chip(self, x, y, s, on=False, w=None):
        t = self.t; f = font(13, 600 if on else 500)
        tw = self.d.textlength(s, font=f); w = w or int(tw) + 24
        self.rect(x, y, w, 32, fill=t["primary"] if on else t["surfaceContainerHigh"], r=16)
        self.text(x + 12, y + 8, s, 13, t["onPrimary"] if on else t["onSurface"], 600 if on else 500)
        return w
    def button(self, x, y, s, primary=True, w=None):
        t = self.t; f = font(14, 600)
        w = w or int(self.d.textlength(s, font=f)) + 32
        self.rect(x, y, w, 44, fill=t["primary"] if primary else None, outline=None if primary else t["outline"], r=12)
        self.text(x + 16, y + 12, s, 14, t["onPrimary"] if primary else t["primary"], 600)
        return w
    def creature(self, cx, cy, name, kind, online=True, r=18, label=True):
        t = self.t; col = t["primary"] if online else t["outline"]
        # species by shape: ray = diamond, whale = ellipse, fish = triangle, others = circle
        if kind == "ray": self.d.polygon([(cx, cy - r), (cx + r * 1.4, cy), (cx, cy + r * 0.7), (cx - r * 1.4, cy)], outline=col)
        elif kind == "whale": self.d.ellipse([cx - r * 1.6, cy - r * 0.7, cx + r * 1.6, cy + r * 0.7], outline=col)
        elif kind == "fish": self.d.polygon([(cx - r, cy), (cx + r * 0.6, cy - r * 0.6), (cx + r * 0.6, cy + r * 0.6)], outline=col)
        else: self.d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col)
        if online: self.d.ellipse([cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8], fill=col + "22")
        if label: self.text(cx, cy + r + 10, name, 13, t["onSurface"] if online else t["onSurfaceVariant"], 500, anchor="ma")
    def jelly(self, cx, cy):
        t = self.t
        self.d.ellipse([cx - 28, cy - 22, cx + 28, cy + 10], outline=t["onSurface"], width=2)
        for i in range(-2, 3): self.d.line([(cx + i * 10, cy + 10), (cx + i * 14, cy + 70)], fill=t["primary"], width=2)
        self.rect(cx + 36, cy - 30, 44, 24, fill=t["primary"], r=12); self.text(cx + 44, cy - 27, "you", 13, t["onPrimary"], 600)
    def sea(self, x, y, w, h, peers, zoom=True, filters=True, card=None, empty=False):
        """The aquarium map, the only place where the deep sea lives."""
        t = self.t
        self.rect(x, y, w, h, fill=t["surfaceContainerLowest"], r=0)
        self.d.line([(x, y + 24), (x + w, y + 24)], fill=t["outline"], width=1)  # the surface line
        cx = x + w // 2; self.jelly(cx, y + 90)
        for i, ms in enumerate((15, 80, 320)):  # sonar arcs: distance = latency (log)
            rr = 120 + i * 110
            self.d.arc([cx - rr, y + 80 - rr, cx + rr, y + 80 + rr], 20, 160, fill=t["outline"] + "66")
            self.text(cx + rr - 8, y + 80 + rr - 20, f"< {ms} ms", 11, t["onSurfaceVariant"], mono=True, anchor="ra")
        if empty:
            self.text(cx, y + h // 2, "No creature yet", 20, t["onSurface"], 600, anchor="ma")
            self.text(cx, y + h // 2 + 30, "Add a device on another machine with the install key.", 13, t["onSurfaceVariant"], anchor="ma")
        import math
        n = len(peers)
        for i, (name, kind, ms, on) in enumerate(peers):
            a = math.pi * (0.25 + 0.5 * (i + 0.5) / max(n, 1))
            rad = 110 + 110 * (math.log(ms, 2) - 2) / 6
            px, py = int(cx + rad * 1.6 * math.cos(a) * (w / 900)), int(y + 90 + rad * math.sin(a) * (h / 600))
            if on: self.d.line([(cx, y + 90), (px, py)], fill=t["data2" if i == 0 else "primary"] + "99", width=4 if i == 0 else 2)
            self.creature(px, py, name, kind, on)
        self.rect(x, y + h - 48, w, 48, fill=t["surfaceContainerLow"], r=0)  # sandy floor with caves
        for j, cave in enumerate(("home-lan", "lab")):
            self.d.pieslice([x + 24 + j * 110, y + h - 70, x + 100 + j * 110, y + h - 10], 180, 360, fill=t["surfaceContainerHigh"])
            self.text(x + 62 + j * 110, y + h - 28, cave, 12, t["onSurface"], 500, anchor="ma")
        self.text(x + w - 16, y + h - 32, "8/10 online · ↓ 21 Mb/s ↑ 4.3 Mb/s", 13, t["onSurfaceVariant"], 500, mono=True, anchor="ra")
        if zoom:  # zoom: a vertical depth gauge, 44 px targets
            for k, s in enumerate(("+", "−", "fit")):
                self.rect(x + w - 60, y + 40 + k * 48, 44, 44, fill=t["surfaceContainerHigh"], r=12)
                self.text(x + w - 38, y + 52 + k * 48, s, 14, t["onSurface"], 600, anchor="ma")
        if filters:  # tag / group filters: chips, one row
            fx = x + 16
            for s, on in (("All", True), ("#servers", False), ("#home", False), ("3 busy", False), ("3 quiet", False)):
                fx += self.chip(fx, y + 40, s, on) + 8
        if card:  # peer card, anchored to the creature, actions as chips
            cx2, cy2 = x + w - 340, y + 100
            self.rect(cx2, cy2, 300, 240, fill=t["surfaceContainer"], outline=t["outline"], r=16)
            self.text(cx2 + 16, cy2 + 14, card, 16, t["onSurface"], 600)
            self.text(cx2 + 16, cy2 + 40, "100.64.0.12 · 12 ms · 2 d 4 h", 12, t["onSurfaceVariant"], mono=True)
            self.text(cx2 + 16, cy2 + 64, "↓ 15 Mb/s   ↑ 1.2 Mb/s", 14, t["primary"], 600, mono=True)
            self.d.line([(cx2 + 16 + i, cy2 + 120 - int(20 * abs(((i * 7) % 23) / 23))) for i in range(0, 268, 4)], fill=t["primary"], width=2)
            ax = cx2 + 16
            for s in ("Send a file", "Browse", "SSH", "★"):
                ax += self.chip(ax, cy2 + 180, s, s == "Send a file") + 8
    def send(self, x, y, w, h, queue=True, error=False, long=False):
        t = self.t
        self.text(x, y, "Send", 22, t["onSurface"], 600)
        self.rect(x, y + 44, w, 120, outline=t["primary"], r=16)
        self.d.rounded_rectangle([x + 4, y + 48, x + w - 5, y + 159], 14, outline=t["primary"] + "55")
        self.text(x + w // 2, y + 84, "Drop files here, or press Ctrl+O", 15, t["onSurface"], 600, anchor="ma")
        self.text(x + w // 2, y + 110, "They go to the selected devices below.", 13, t["onSurfaceVariant"], anchor="ma")
        self.text(x, y + 184, "To", 13, t["onSurfaceVariant"], 600)
        dx = x
        for s, on in (("atlas-server", True), ("reef-nas", True), ("nova-laptop", False), ((LONG[:28] + "…") if long else "kite-phone", False)):
            dx += self.chip(dx, y + 204, s, on) + 8
        self.text(x, y + 256, "Queue", 13, t["onSurfaceVariant"], 600)
        rows = [("report-q3.pdf", "atlas-server", 0.72, "sending"), ("photos-2026.zip", "reef-nas", 1.0, "done"),
                ("backup.tar", "atlas-server", 0.18, "failed" if error else "sending")]
        if long: rows[0] = (LONG + ".pdf", LONG, 0.72, "sending")
        for i, (f, dev, p, st) in enumerate(rows):
            ry = y + 280 + i * 56
            self.rect(x, ry, w, 48, fill=t["surfaceContainerLow"], r=12)
            fname = f if len(f) < 40 else f[:18] + "…" + f[-18:]  # middle ellipsis keeps the extension
            self.text(x + 12, ry + 8, fname, 14, t["onSurface"], 600)
            self.text(x + 12, ry + 28, ("→ " + (dev if len(dev) < 30 else dev[:28] + "…")), 12, t["onSurfaceVariant"])
            col = t["error"] if st == "failed" else (t["success"] if st == "done" else t["primary"])
            self.rect(x + w - 200, ry + 18, 120, 8, fill=t["surfaceContainerHighest"], r=4)
            self.rect(x + w - 200, ry + 18, int(120 * p), 8, fill=col, r=4)
            lab = {"failed": "Failed · Retry", "done": "Done", "sending": f"{int(p*100)} % · 4.1 MB/s"}[st]
            self.text(x + w - 12, ry + 14, lab, 12, col, 600, mono=True, anchor="ra")
            if st != "done": self.text(x + w - 12, ry + 30, "Cancel" if st == "sending" else "Dismiss", 12, t["onSurfaceVariant"], 600, anchor="ra")
        if error:
            self.rect(x, y + 456, w, 44, fill=t["error"] + "22", outline=t["error"], r=12)
            self.text(x + 12, y + 469, "backup.tar: atlas-server refused the connection (port 22 closed). Retry, or open the guide.", 13, t["onSurface"], 500)
        self.text(x, y + 520, "History", 13, t["onSurfaceVariant"], 600)
        for i, (f, dev, when) in enumerate((("notes.md", "nova-laptop", "today 10:12"), ("deck.key", "kite-phone", "yesterday"))):
            self.text(x, y + 544 + i * 24, f"{f}  →  {dev}", 13, t["onSurface"]); self.text(x + w, y + 544 + i * 24, when, 12, t["onSurfaceVariant"], mono=True, anchor="ra")
    def settings(self, x, y, w, h):
        t = self.t
        self.text(x, y, "Settings", 22, t["onSurface"], 600)
        self.rect(x, y + 44, w, 44, fill=t["surfaceContainerLow"], outline=t["outline"], r=12)
        self.text(x + 16, y + 56, "Search a setting…   ( / )", 14, t["onSurfaceVariant"])
        cats = ("General", "Map", "Send", "Creatures", "Networks", "Privacy", "About")
        for i, c in enumerate(cats):
            on = i == 2
            self.rect(x, y + 108 + i * 44, 180, 40, fill=t["surfaceContainerHigh"] if on else None, r=12)
            self.text(x + 16, y + 118 + i * 44, c, 14, t["onSurface"], 600 if on else 500)
        cx = x + 204
        for i, (lab, val) in enumerate((("Send folder", "~/Downloads/Abyss"), ("Ask before overwriting", "On"), ("Keep history", "30 days"),
                                        ("Speed limit", "Off"), ("Open received files", "Off"))):
            ry = y + 108 + i * 56
            self.text(cx, ry + 4, lab, 15, t["onSurface"], 500); self.text(cx, ry + 26, "Where received files land. Plain folder, never synced.", 12, t["onSurfaceVariant"])
            self.rect(x + w - 56, ry + 6, 48, 28, fill=t["primary"] if val == "On" else t["surfaceContainerHighest"], r=14)
            if val not in ("On", "Off"): self.text(x + w - 8, ry + 10, val, 13, t["primary"], 600, mono=True, anchor="ra")
    def firstrun(self, x, y, w, h):
        t = self.t
        self.rect(x, y, w, h, fill=t["surfaceContainerLowest"], r=0)
        cx = x + w // 2; self.jelly(cx, y + h // 2 - 60)
        self.text(cx, y + h // 2 + 40, "Welcome to the abyss", 24, t["onSurface"], 600, anchor="ma")
        self.text(cx, y + h // 2 + 76, "Darwin has not found NetBird on this machine yet.", 14, t["onSurfaceVariant"], anchor="ma")
        self.button(cx - 150, y + h // 2 + 110, "Install NetBird", True, 140); self.button(cx + 10, y + h // 2 + 110, "I have a key", False, 140)
    def errorbar(self, x, y, w, msg):
        t = self.t
        self.rect(x, y, w, 44, fill=t["error"] + "22", outline=t["error"], r=12)
        self.text(x + 12, y + 13, msg, 13, t["onSurface"], 500)
        self.text(x + w - 12, y + 13, "Open the guide ↗", 13, t["primary"], 600, anchor="ra")

def render(direction, theme, state, out):
    t = DARK if theme == "dark" else LIGHT
    W, H = (900, 600) if state == "window-900x600" else (1280, 800)
    b = Board(W, H, t)
    view = {"send": "send", "settings": "settings", "first-run": "first", "error": "send", "long-names": "map"}.get(state, "map")
    peers = [] if state == "empty" else PEERS
    long = state == "long-names"
    if long: peers = [(LONG, "ray", 12, True)] + PEERS[1:]
    rail_h = 40
    if direction == "A":  # Porthole: the map is the window; a floating rail; slates slide over the dimmed sea
        b.sea(0, 0, W, H, peers, card="atlas-server" if state in ("map", "window-1280x800", "window-900x600") else None, empty=state == "empty")
        b.rect(16, 12, W - 32, rail_h, fill=t["surfaceContainer"] + "f0", r=20)
        rx = 28
        for s in ("Map", "Send", "Settings"):
            rx += b.chip(rx, 16, s, (view == "map" and s == "Map") or (view == "send" and s == "Send") or (view == "settings" and s == "Settings")) + 8
        b.text(W - 32, 23, "Search a creature ( / )", 13, t["onSurfaceVariant"], anchor="ra")
        if view in ("send", "settings"):
            pw = min(560, W - 64); px = W - pw - 16
            b.d.rectangle([0, 0, W, H], fill=t["surface"] + "99")
            b.rect(px, 64, pw, H - 80, fill=t["surfaceContainer"], outline=t["outline"], r=20)
            (b.send if view == "send" else b.settings)(px + 24, 88, pw - 48, H - 128, **({"error": state == "error"} if view == "send" else {}))
        if view == "first": b.firstrun(0, 0, W, H)
    elif direction == "B":  # Deck: a lit left deck, the sea below it on the right
        deck = 72
        b.rect(0, 0, deck, H, fill=t["surfaceContainer"], r=0)
        for i, s in enumerate(("Map", "Send", "Set.", "Help")):
            on = (view, s) in (("map", "Map"), ("send", "Send"), ("settings", "Set."))
            b.rect(14, 16 + i * 56, 44, 44, fill=t["primary"] if on else None, r=12)
            b.text(36, 30 + i * 56, s, 11, t["onPrimary"] if on else t["onSurface"], 600, anchor="ma")
        if view == "map":
            b.sea(deck, 0, W - deck, H, peers, card="atlas-server" if state != "empty" else None, empty=state == "empty")
        elif view == "first": b.firstrun(deck, 0, W - deck, H)
        else:
            (b.send if view == "send" else b.settings)(deck + 48, 40, min(760, W - deck - 96), H - 80, **({"error": state == "error"} if view == "send" else {}))
    else:  # C Water column: depth is navigation, light level follows the view
        gauge = 56
        b.rect(0, 0, gauge, H, fill=t["surfaceContainerLow"], r=0)
        for i, (s, dep) in enumerate((("Set.", "0 m"), ("Send", "200 m"), ("Map", "4 000 m"))):
            on = (view, s) in (("map", "Map"), ("send", "Send"), ("settings", "Set."))
            b.d.line([(28, 40 + i * 120), (28, 160 + i * 120)], fill=t["outline"], width=2)
            b.d.ellipse([20, 92 + i * 120, 36, 108 + i * 120], fill=t["primary"] if on else t["outline"])
            b.text(28, 112 + i * 120, s, 11, t["onSurface"], 600, anchor="ma"); b.text(28, 128 + i * 120, dep, 10, t["onSurfaceVariant"], mono=True, anchor="ma")
        if view == "map":
            b.sea(gauge, 0, W - gauge, H, peers, card="atlas-server" if state != "empty" else None, empty=state == "empty")
        elif view == "first": b.firstrun(gauge, 0, W - gauge, H)
        else:
            # mid-water / surface: lighter container, the sea still glows at the bottom edge
            b.rect(gauge, 0, W - gauge, H, fill=t["surfaceContainerLow"] if view == "send" else t["surface"], r=0)
            b.d.rectangle([gauge, H - 24, W, H], fill=t["surfaceContainerLowest"])
            (b.send if view == "send" else b.settings)(gauge + 48, 40, min(760, W - gauge - 96), H - 80, **({"error": state == "error"} if view == "send" else {}))
    if state == "error" and direction != "A":
        b.errorbar(W - 560, H - 68, 536, "NetBird is not running. Start it, or open the guide.")
    if state == "error" and direction == "A":
        b.errorbar(16, H - 68, W - 32, "NetBird is not running. Start it, or open the guide.")
    b.text(W - 8, H - 16, f"{direction} · {theme} · {state} · fictional data", 10, t["onSurfaceVariant"], mono=True, anchor="ra")
    b.im.save(out)

STATES = ("window-1280x800", "window-900x600", "map", "send", "settings", "first-run", "empty", "error", "long-names")
if __name__ == "__main__":
    if "--table" in sys.argv: table(); sys.exit()
    outdir = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
    for d in "ABC":
        for th in ("dark", "light"):
            os.makedirs(f"{outdir}/{d}/{th}", exist_ok=True)
            for s in STATES: render(d, th, s, f"{outdir}/{d}/{th}/{s}.png")
    print("ok")
