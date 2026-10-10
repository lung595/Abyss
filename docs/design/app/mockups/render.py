#!/usr/bin/env python3
"""Real-size PNG mockups of the Abyss app v1 screens (NAK-286, option A).

Not production code. Reuses the palette, fonts and drawing helpers of the
direction wireframes (`../render.py`) so every value comes from the same
token list (mockups/README.md §5). Fictional data only. No browser exists on
the machine (Q104), so these PNGs are what the owner reviews; the HTML file
stays the interactive reference. Run: python3 render.py
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import render as base  # noqa: E402
from render import Board, DARK, LIGHT, PEERS, LONG, contrast  # noqa: E402
from PIL import ImageFont  # noqa: E402


def font(size, weight=400, mono=False):
    """Basic layout: the raqm engine mis-advances variable-font instances ("#hom e")."""
    f = ImageFont.truetype(base.MONO if mono else base.FONT, size, layout_engine=ImageFont.Layout.BASIC)
    f.set_variation_by_axes([weight])
    return f


base.font = font  # Board.text/chip/button resolve `font` from their module

# NotoSans has no geometric symbols: pick the Noto face that owns each glyph
SYMBOL_FONTS = {"/usr/share/fonts/google-noto/NotoSansSymbols2-Regular.ttf": "●○◐★✕⚠◉⌖☼⌘•",
                "/usr/share/fonts/google-noto-vf/NotoSansSymbols[wght].ttf": "♪⚑"}
# One extra role, asked by the review: a border that passes 3:1 on every stratum
# (`outline` only passes on surface…surfaceContainer). Dividers keep `outline`.
OUTLINE_STRONG = {False: "#8592b8", True: "#5a6a82"}
HOVER, PRESSED, DISABLED = "14", "1f", "61"  # onSurface alpha 0.08 / 0.12, 38 % content

W, H, GAUGE, PAD, TITLE = 1280, 800, 72, 32, 44
STATIONS = [("Settings", 0, "surfaceContainerHighest", "surfaceContainerLowest"),
            ("Send", 200, "surfaceContainer", "surfaceContainerLow"),
            ("Map", 4000, "surfaceContainerLowest", "surfaceContainerHigh")]
MANY = [(f"{n}-{k}", k, 5 + i * 7, i % 5 != 4) for i, (n, k) in enumerate(
    zip("atlas harbor nova reef kite pi dune orca coral tide brine kelp moss gull wave foam silt drift shoal delta fjord lagoon buoy mast keel helm reef2 cove bay".split(),
        ("ray whale fish turtle horse squid nautilus".split() * 5)))][:30]


class App(Board):
    """One 1280×800 window: depth gauge + one flat stratum per station."""

    def __init__(self, t, station, signal="ok"):
        t = dict(t, outlineStrong=OUTLINE_STRONG[t["isLightMode"]])
        super().__init__(W, H, t)
        self.station, self.signal = station, signal
        name, depth, dark, light = STATIONS[station]
        self.rect(GAUGE, 0, W - GAUGE, H, fill=t[light if t["isLightMode"] else dark], r=0)
        self.gauge(depth)
        self.text(GAUGE + PAD, 36, name, 22, weight=600)
        self.text(GAUGE + PAD + self.d.textlength(name, font=font(22, 600)) + 12, 44,
                  f"· {depth:,} m".replace(",", " "), 13, t["onSurfaceVariant"], mono=True)

    def glyph(self, x, y, ch, size=13, color=None, anchor="la"):
        """Draw one symbol with a font that really has it (arrows live in the mono face)."""
        path = next((f for f, chars in SYMBOL_FONTS.items() if ch in chars), None)
        f = ImageFont.truetype(path, size) if path else font(size, 400, True)
        self.d.text((x, y), ch, fill=color or self.t["onSurface"], font=f, anchor=anchor)

    def chip(self, x, y, s, on=False, w=None, close=False, state=None):
        """Chip with a visible container (fill + 1 px outlineStrong), optional ✕ (44 px hit) and states."""
        t = self.t; s2 = s + ("     " if close else "")
        w = w or int(self.d.textlength(s2, font=font(13, 600 if on else 500))) + 24
        self.rect(x, y, w, 32, fill=t["primary"] if on else t["surfaceContainerHigh"], outline=None if on else t["outlineStrong"], r=16)
        self.text(x + 12, y + 8, s2, 13, t["onPrimary"] if on else t["onSurface"], 600 if on else 500)
        if close: self.glyph(x + w - 22, y + 16, "✕", 12, t["onPrimary"] if on else t["onSurface"], "mm")
        self.state(x, y, w, 32, 16, state)
        return w

    def button(self, x, y, s, primary=True, w=None, state=None):
        t = self.t; w = w or int(self.d.textlength(s, font=font(14, 600))) + 32
        self.rect(x, y, w, 44, fill=t["primary"] if primary else None, outline=None if primary else t["outlineStrong"], r=12)
        self.text(x + 16, y + 12, s, 14, t["onPrimary"] if primary else t["primary"], 600)
        self.state(x, y, w, 44, 12, state)
        return w

    def state(self, x, y, w, h, r, state):
        """Interaction layers shared by every control: hover/pressed = onSurface veil,
        focus-visible = 2 px primary ring at 2 px offset, disabled = 38 % content."""
        t = self.t
        if state in ("hover", "pressed"): self.rect(x, y, w, h, fill=t["onSurface"] + (HOVER if state == "hover" else PRESSED), r=r)
        elif state == "focus": self.d.rounded_rectangle([x - 3, y - 3, x + w + 2, y + h + 2], r + 3, outline=t["primary"], width=2)
        elif state == "disabled": self.rect(x, y, w, h, fill=self.bg + "9e", r=r)  # 62 % veil of the stratum = 38 % content

    @property
    def bg(self):
        name, _, dark, light = STATIONS[self.station]
        return self.t[light if self.t["isLightMode"] else dark]

    def gauge(self, depth):
        t = self.t
        self.rect(0, 0, GAUGE, H, fill=t["surfaceContainer"], r=0)
        self.d.line([(GAUGE - 1, 0), (GAUGE - 1, H)], fill=t["outline"])
        top, bottom = 64, 584  # 0 m ring top at y 42, readouts end at y 758: 42 px both ends
        for i in range(0, 131):  # minor tick every 4 px, major every 100 m
            y = top + i * 4; major = i % 10 == 0
            self.d.line([(GAUGE - 24 if major else GAUGE - 16, y), (GAUGE - 8, y)], fill=t["outline"] if major else t["outline"] + "66")
        for d in range(0, 4001, 1000):
            self.text(GAUGE - 28, top + int(d / 4000 * (bottom - top)), f"{d // 1000}k" if d else "0", 11, t["onSurfaceVariant"], mono=True, anchor="rm")
        for k, (name, d, _, _) in enumerate(STATIONS):
            y = top + int(d / 4000 * (bottom - top)); cur = k == self.station
            if cur:
                self.d.ellipse([2, y - 22, 46, y + 22], outline=t["primary"], width=2)
                self.d.ellipse([10, y - 14, 38, y + 14], fill=t["primary"])
                self.darwin(GAUGE + 12, y)
            else:
                self.d.ellipse([10, y - 14, 38, y + 14], outline=t["outlineStrong"], width=1)
        # instrument readouts (mono, tabular): the glyph changes with the state, never colour alone
        glyph, col = {"ok": ("●", "success"), "warn": ("◐", "warning"), "stop": ("○", "error")}[self.signal]
        temp = {0: 18, 200: 6, 4000: 2}[depth]
        for j, (s, c) in enumerate([(f"{depth:>5} m", "onSurface"), (f"{depth / 10 + 1:>5.0f} bar", "onSurfaceVariant"),
                                    (f"{temp:>5} °C", "onSurfaceVariant"), (f"{glyph} signal", col)]):
            self.text(8, 682 + j * 20, s, 11, t[c], mono=True)  # mono face owns ●◐○

    def darwin(self, x, y):
        """The small fish mascot hanging beside the current station (24 px)."""
        c = self.t["secondary"]
        self.d.polygon([(x, y), (x + 14, y - 7), (x + 14, y + 7)], fill=c)
        self.d.polygon([(x + 14, y), (x + 24, y - 6), (x + 24, y + 6)], fill=c)

    def creature(self, cx, cy, name, kind, online=True, r=18, label=True):
        """Creatures share one stroke: 24 grid scaled by r/12, 2 px line, at most 2 details (eye, one fin)."""
        t = self.t; col = t["primary"] if online else t["outline"]; k = r / 12
        P = lambda *pts: [(cx + px * k, cy + py * k) for px, py in pts]
        E = lambda x0, y0, x1, y1: [cx + x0 * k, cy + y0 * k, cx + x1 * k, cy + y1 * k]
        eye = lambda ex, ey: self.d.ellipse(E(ex - 1.2, ey - 1.2, ex + 1.2, ey + 1.2), fill=col)
        if online: self.d.ellipse(E(-16, -16, 16, 16), fill=col + "22")
        if kind == "ray": self.d.polygon(P((-12, 0), (0, -7), (12, 0), (0, 7)), outline=col, width=2); self.d.line(P((0, 7), (-2, 12)), fill=col, width=2); eye(3, -2)
        elif kind == "whale": self.d.ellipse(E(-12, -6, 8, 6), outline=col, width=2); self.d.polygon(P((8, 0), (12, -5), (12, 5)), outline=col, width=2); eye(-7, -2)
        elif kind == "fish": self.d.polygon(P((-10, 0), (6, -7), (6, 7)), outline=col, width=2); self.d.line(P((6, 0), (11, 0)), fill=col, width=2); eye(-5, -1)
        elif kind == "turtle": self.d.ellipse(E(-9, -6, 9, 6), outline=col, width=2); self.d.ellipse(E(8, -3, 13, 2), outline=col, width=2); eye(10, -1)
        elif kind == "horse": self.d.line(P((2, -11), (6, -8), (2, -3), (-4, 2), (0, 8), (4, 11)), fill=col, width=2, joint="curve"); eye(3, -8)
        elif kind == "squid": self.d.polygon(P((-9, -3), (0, -11), (9, -3), (0, 3)), outline=col, width=2); self.d.line(P((-4, 3), (-4, 11)), fill=col, width=2); self.d.line(P((4, 3), (4, 11)), fill=col, width=2)
        else: self.d.ellipse(E(-10, -10, 10, 10), outline=col, width=2); self.d.arc(E(-5, -5, 5, 5), 90, 360, fill=col, width=2); eye(-7, 0)
        if label: self.text(cx, cy + r + 10, name, 13, t["onSurface"] if online else t["onSurfaceVariant"], 500, anchor="ma")

    def github(self, cx, cy):
        """The GitHub mark at 24 px (circle, cat head with ears, tail), onSurface on the band."""
        t = self.t; on, off = t["onSurface"], t["surface"]
        self.d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=on)
        self.d.polygon([(cx - 6, cy - 2), (cx - 6, cy - 7), (cx - 3, cy - 4), (cx + 3, cy - 4), (cx + 6, cy - 7), (cx + 6, cy - 2)], fill=off)
        self.d.ellipse([cx - 6, cy - 6, cx + 6, cy + 4], fill=off)
        self.d.rectangle([cx - 3, cy + 3, cx + 3, cy + 9], fill=off)
        self.d.arc([cx - 9, cy + 1, cx - 2, cy + 9], 90, 220, fill=off, width=2)

    # ---- bands and guided messages (value 10) ----
    def band(self, y, msg, kind="warning", action=None, guide=False):
        t = self.t; x, w = GAUGE + PAD, W - GAUGE - 2 * PAD
        self.rect(x, y, w, 44, fill=t[kind] + "21", outline=t[kind], r=12)
        self.glyph(x + 16, y + 14, "⚠" if kind == "warning" else "✕", 13, t[kind]); self.text(x + 36, y + 14, msg, 13, t["onSurface"], 500)
        ax = x + w - 16
        if guide:  # GitHub mark → docs/GUIDE.md anchor, opened on click only
            self.github(ax - 12, y + 22); ax -= 36
        if action:
            w2 = int(self.d.textlength(action, font=font(13, 600))) + 24
            self.rect(ax - w2, y + 6, w2, 32, fill=t[kind], r=16); self.text(ax - w2 + 12, y + 14, action, 13, t["onSurface" if t["isLightMode"] else "surface"], 600)

    def panel(self, title, h=480):
        t = self.t; x, y = (W + GAUGE) // 2 - 280, (H - h) // 2
        self.rect(GAUGE, 0, W - GAUGE, H, fill=t["surface"] + "99", r=0)
        self.rect(x, y, 560, h, fill=t["surfaceContainer"], outline=t["outlineStrong"], r=20)
        self.text(x + 24, y + 22, title, 22, weight=600); self.glyph(x + 524, y + 34, "✕", 18, t["onSurfaceVariant"], "mm")
        return x, y


def sparkline(b, x, y, w, h, seed=3):
    pts = [(x + i * w // 23, y + h - 2 - ((i * seed * 7) % (h - 4))) for i in range(24)]
    b.d.line(pts, fill=b.t["primary"], width=2)


# ---------------- screens ----------------
def map_screen(t, peers=PEERS, card=True, empty=False, long=False, signal="ok"):
    b = App(t, 2, signal); x, y, w, h = GAUGE + PAD, PAD + TITLE + 8, W - GAUGE - 2 * PAD, H - PAD * 2 - TITLE - 48
    b.rect(x, y, w, h, fill=t["surfaceContainerLowest"] if not t["isLightMode"] else t["surfaceContainerHigh"], outline=b.t["outlineStrong"], r=16)
    cx = x + 16; cx += b.chip(cx, y + 16, "All", True) + 8
    for s in ("#servers", "#home", "lab"): cx += b.chip(cx, y + 16, s) + 8
    for i, g in enumerate(["+", "−", "⌖"]):  # zoom in, zoom out, centre on me
        b.rect(x + w - 60, y + 16 + i * 48, 44, 44, outline=b.t["outlineStrong"], r=12); b.glyph(x + w - 38, y + 38 + i * 48, g, 18, anchor="mm")
    b.jelly(x + w // 2, y + 120)
    if empty:
        b.text(x + w // 2, y + 300, "No creature yet", 22, weight=600, anchor="ma")
        b.text(x + w // 2, y + 336, "Add a device from the + at the top right, or wait: NetBird is listening.", 13, t["onSurfaceVariant"], anchor="ma")
    else:
        if len(peers) > 8:  # 30 peers: caves per group + compact list under the sea
            for k, (gname, n) in enumerate([("servers", 9), ("home", 8), ("lab", 7), ("other", 6)]):
                gx = x + 200 + k * 220; b.d.ellipse([gx - 70, y + 330, gx + 70, y + 420], outline=b.t["outlineStrong"], width=1)
                b.text(gx, y + 362, gname, 15, weight=600, anchor="ma"); b.text(gx, y + 386, f"{n} creatures", 13, t["onSurfaceVariant"], mono=True, anchor="ma")
            for i, (n, k, ms, on) in enumerate(peers[:24]):
                b.text(x + 16 + (i % 6) * 190, y + h - 70 + (i // 6) * 16, ("● " if on else "○ ") + n, 11, t["onSurface"] if on else t["onSurfaceVariant"], mono=True)
        else:
            for i, (n, k, ms, on) in enumerate(peers):
                px, py = x + 120 + (i % 4) * 250, y + 240 + (i // 4) * 200
                b.creature(px, py, LONG[:14] + "…" + LONG[-9:] if long and i == 0 else n, k, on)
        if card:
            px, py = x + w - 76 - 300, y + 80
            b.rect(px, py, 300, 240, fill=t["surfaceContainer"], outline=b.t["outlineStrong"], r=16)
            b.text(px + 16, py + 16, (LONG[:12] + "…" + LONG[-8:]) if long else "atlas-server", 15, weight=600)
            b.text(px + 16, py + 40, "100.64.0.12 · 12 ms · 9 d", 13, t["onSurfaceVariant"], mono=True)
            sparkline(b, px + 16, py + 64, 240, 24)
            b.glyph(px + 16, py + 98, "●", 13, t["success"]); b.text(px + 32, py + 98, "Direct · 12 ms · healthy", 13, t["success"], 500)
            bx = px + 16; bx += b.chip(bx, py + 128, "Send a file", True) + 8; bx += b.chip(bx, py + 128, "Browse files") + 8; b.chip(bx, py + 128, "SSH")
            b.chip(px + 16, py + 172, "    Favourite"); b.glyph(px + 36, py + 188, "★", 13, anchor="mm"); b.chip(px + 140, py + 172, "Diagnosis")
    b.text(x, H - PAD - 16, "8/10 online · ↓ 21 Mb/s · ↑ 4.3 Mb/s", 13, t["onSurfaceVariant"], mono=True)
    if signal == "stop": b.band(H - PAD - 60, "NetBird is stopped: creatures are asleep.", "warning", "Start NetBird")
    return b


def send_screen(t, refused=False, long=False, signal="ok"):
    b = App(t, 1, signal); x, y, w = GAUGE + PAD, PAD + TITLE + 8, W - GAUGE - 2 * PAD
    b.rect(x, y, w, 120, outline=t["primary"], r=16); b.d.rounded_rectangle([x + 8, y + 8, x + w - 9, y + 111], 12, outline=t["outline"] + "88")
    b.text(x + w // 2, y + 44, "Drop files here, or press Ctrl+O", 15, t["onSurfaceVariant"], 500, anchor="ma")
    b.text(x, y + 148, "To", 13, t["onSurfaceVariant"]); cx = x + 40
    for s, on in (("atlas-server", True), ("reef-nas", True), (("a-very-long-device-name-that…" if long else "nova-laptop"), False)): cx += b.chip(cx, y + 136, s, on) + 8
    rows = [("quarterly-report-final-v3.pdf", "atlas-server", 42, "8.1 MB/s", "Cancel"), ("holiday-photos-2026.tar", "reef-nas", None, "", "Cancel"),
            ("notes.md", "atlas-server", 100, "done", "Dismiss")]
    if long: rows[0] = (LONG[:18] + "…" + LONG[-6:] + ".pdf", LONG[:10] + "…", 42, "8.1 MB/s", "Cancel")
    yy = y + 192
    for i, (name, dev, pct, spd, act) in enumerate(rows):
        ry = yy + i * 56; b.d.line([(x, ry + 55), (x + w, ry + 55)], fill=t["outline"] + "66")
        b.d.rounded_rectangle([x + 2, ry + 20, x + 14, ry + 36], 6, fill=t["primary"] if pct != 100 else t["outline"])
        b.text(x + 28, ry + 10, name, 15, weight=500); b.text(x + 28, ry + 32, "→ " + dev, 12, t["onSurfaceVariant"])
        tx = x + w - 500; b.rect(tx, ry + 24, 120, 8, fill=t["surfaceContainerHighest"], r=4)
        if pct is None: b.rect(tx + 40, ry + 24, 36, 8, fill=t["primary"], r=4); b.text(tx + 136, ry + 20, "Sending · scp, no progress", 13, mono=True)
        else: b.rect(tx, ry + 24, int(1.2 * pct), 8, fill=t["primary"], r=4); b.d.ellipse([tx + int(1.2 * pct) - 6, ry + 22, tx + int(1.2 * pct) + 6, ry + 34], fill=t["primary"]); b.text(tx + 136, ry + 20, f"{pct:>3} %", 13, mono=True)
        b.text(tx + 200, ry + 20, spd, 13, t["onSurfaceVariant"], mono=True); b.button(x + w - 100, ry + 6, act, False, 100)
    if refused: b.band(yy + 176, "Send refused: reef-nas does not accept files from you. Ask its owner to allow your key.", "error", "Retry", guide=True)
    hy = yy + 240; b.text(x, hy, "History", 15, weight=600)
    for i, (n, d, when, sz) in enumerate([("build-2026-10.log", "harbor-vps", "yesterday", "2.3 MB"), ("backup.tar.zst", "reef-nas", "3 d ago", "1.8 GB")]):
        b.text(x, hy + 32 + i * 44, n, 15, weight=500); b.text(x, hy + 52 + i * 44, f"→ {d} · {when} · {sz}", 12, t["onSurfaceVariant"], mono=True)
    if signal == "stop": b.band(H - PAD - 60, "NetBird is stopped: nothing can be sent.", "warning", "Start NetBird")
    return b


def settings_screen(t, signal="ok"):
    b = App(t, 0, signal); x, y, w = GAUGE + PAD, PAD + TITLE + 8, W - GAUGE - 2 * PAD
    b.rect(x, y, w, 44, fill=t["surfaceContainerLow"] if t["isLightMode"] else t["surfaceContainer"], outline=b.t["outlineStrong"], r=12); b.text(x + 16, y + 13, "Search settings   /", 15, t["onSurfaceVariant"])
    for i, (ic, s) in enumerate([("◉", "Network"), ("↓", "Sending"), ("☼", "Appearance"), ("♪", "Sounds"), ("⌘", "Shortcuts"), ("⚑", "Privacy")]):
        on = i == 1; b.rect(x, y + 68 + i * 48, 200, 40, fill=t["primary"] if on else None, r=12)
        b.glyph(x + 20, y + 88 + i * 48, ic, 14, t["onPrimary"] if on else t["onSurface"], "mm"); b.text(x + 40, y + 78 + i * 48, s, 15, t["onPrimary"] if on else t["onSurface"], 600 if on else 500)
    rx = x + 232
    for i, (lab, help_, kind) in enumerate([("Receive folder", "Where files you receive are saved", "~/Downloads/Abyss"), ("Ask before receiving", "A capsule waits for your answer", True),
                                             ("Retry failed sends", "Up to 3 times, 10 s apart", False), ("Parallel transfers", "At most, per device", "2"), ("Play a sound on arrival", "Gentle, rate-limited", True)]):
        ry = y + 68 + i * 72; b.text(rx, ry, lab, 15, weight=500); b.text(rx, ry + 24, help_, 12, t["onSurfaceVariant"])
        if kind is True or kind is False:
            b.rect(x + w - 48, ry + 6, 48, 28, fill=t["primary"] if kind else t["surfaceContainerHighest"], outline=None if kind else b.t["outlineStrong"], r=14)
            b.d.ellipse([x + w - 48 + (24 if kind else 4), ry + 10, x + w - 48 + (44 if kind else 24), ry + 30], fill=t["onPrimary"] if kind else b.t["outlineStrong"])
        else: b.chip(x + w - 12 - int(b.d.textlength(kind, font=font(13, 500))) - 24, ry + 4, kind)
    return b


def wizard_screen(t, step=2):
    b = map_screen(t, card=False); x, y = b.panel("Add a device")
    for i, s in enumerate(("Name", "Key", "QR code")):
        b.chip(x + 24 + i * 110, y + 64, f"{i + 1} {s}", i == step - 1)
    if step == 2:
        b.text(x + 24, y + 128, "Setup key", 15, weight=500); b.text(x + 24, y + 152, "Paste it on the new device. It is never shown or logged.", 12, t["onSurfaceVariant"])
        b.rect(x + 24, y + 184, 400, 44, fill=t["surfaceContainerHigh"], outline=b.t["outlineStrong"], r=12); b.text(x + 40, y + 196, "••••••••••••••••••••", 15, mono=True)
        b.rect(x + 436, y + 184, 44, 44, outline=b.t["outlineStrong"], r=12); b.glyph(x + 458, y + 206, "◉", 18, anchor="mm")
        b.chip(x + 492, y + 190, "Copy")
    else:
        for i in range(21 * 21):  # fictional QR payload
            if (i * 7919) % 5 < 2: b.d.rectangle([x + 180 + (i % 21) * 8, y + 120 + (i // 21) * 8, x + 187 + (i % 21) * 8, y + 127 + (i // 21) * 8], fill=t["onSurface"])
        b.text(x + 280, y + 308, "Scan it from the phone", 15, weight=500, anchor="ma")
    b.button(x + 536 - 100, y + 420, "Next", True, 100); b.button(x + 24, y + 420, "Back", False, 100)
    return b


def diagnosis_screen(t):
    b = map_screen(t, card=False); x, y = b.panel("Diagnosis · atlas-server", 520)
    for i, (g, s, c) in enumerate([("●", "Daemon       running", "success"), ("●", "Management   connected", "success"), ("●", "Signal       connected", "success"),
                                   ("●", "Path         direct (no relay)", "success"), ("◐", "Latency      12 ms · jitter 3 ms", "warning"), ("●", "MTU          1280", "success"), ("●", "Handshake    4 s ago", "success")]):
        b.glyph(x + 24, y + 72 + i * 28, g, 13, t[c]); b.text(x + 48, y + 72 + i * 28, s, 13, mono=True)
    b.button(x + 24, y + 288, "Measure throughput (10 s)", True)
    b.text(x + 24, y + 352, "↓ 94 Mb/s · ↑ 41 Mb/s", 15, weight=600, mono=True); sparkline(b, x + 24, y + 384, 240, 24, 5)
    return b


def tags_screen(t):
    b = map_screen(t, card=False); x, y = b.panel("Tags and groups")
    cx = x + 24
    for s, n in (("#servers", 3), ("#home", 2), ("#lab", 4), ("#nas", 1)): cx += b.chip(cx, y + 72, f"{s} {n}", close=True) + 8
    b.rect(x + 24, y + 120, 240, 44, outline=b.t["outlineStrong"], r=12); b.text(x + 40, y + 132, "New tag…", 15, t["onSurfaceVariant"])
    b.text(x + 24, y + 196, "Groups", 15, weight=600)
    for i, (g, tags, k) in enumerate([("Work", "#servers #lab", 5), ("House", "#home #nas", 3)]):
        gy = y + 228 + i * 72; b.rect(x + 24, gy, 512, 60, fill=t["surfaceContainerHigh"], r=12)
        b.text(x + 40, gy + 10, g, 15, weight=500); b.text(x + 40, gy + 34, tags, 12, t["onSurfaceVariant"], mono=True)
        for j in range(k): b.creature(x + 400 + j * 26, gy + 30, "", "fish" if j % 2 else "ray", True, 7, False)
    return b


def firstrun_screen(t):
    b = App(t, 0, "stop"); x = GAUGE + PAD
    b.darwin(x, 220); b.text(x + 40, 208, "NetBird is not installed on this machine.", 22, weight=600)
    b.text(x + 40, 248, "Abyss uses it to find your devices. Install it, then come back: I will be waiting here at the surface.", 15, t["onSurfaceVariant"])
    b.button(x + 40, 300, "Install NetBird", True); b.button(x + 220, 300, "I have a key", False)
    return b


STATES = ["default", "hover", "focus", "pressed", "selected", "disabled"]


def states_screen(t):
    """One board per component: every interaction state side by side (review item 6)."""
    b = App(t, 0); x, y = GAUGE + PAD, PAD + TITLE + 8
    b.text(x + 200, y, "", 13)
    for j, s in enumerate(STATES): b.text(x + 200 + j * 170, y, "focus-visible" if s == "focus" else s, 12, t["onSurfaceVariant"], 500)
    rows = [("Chip", lambda cx, cy, s: b.chip(cx, cy, "#servers", s == "selected", 120, state=None if s == "selected" else s)),
            ("Button, primary", lambda cx, cy, s: b.button(cx, cy, "Send", True, 120, state=s)),
            ("Button, secondary", lambda cx, cy, s: b.button(cx, cy, "Cancel", False, 120, state=s)),
            ("Zoom control", lambda cx, cy, s: (b.rect(cx, cy, 44, 44, outline=b.t["outlineStrong"], r=12), b.glyph(cx + 22, cy + 22, "+", 18, anchor="mm"), b.state(cx, cy, 44, 44, 12, s))),
            ("Switch", lambda cx, cy, s: (b.rect(cx, cy + 8, 48, 28, fill=t["primary"] if s == "selected" else t["surfaceContainerHighest"], outline=None if s == "selected" else b.t["outlineStrong"], r=14),
                                          b.d.ellipse([cx + (24 if s == "selected" else 4), cy + 12, cx + (44 if s == "selected" else 24), cy + 32], fill=t["onPrimary"] if s == "selected" else b.t["outlineStrong"]), b.state(cx, cy + 8, 48, 28, 14, s))),
            ("Queue row", lambda cx, cy, s: (b.rect(cx, cy, 150, 44, fill=t["surfaceContainerHigh"] if s == "selected" else None, r=12), b.d.rounded_rectangle([cx + 10, cy + 14, cx + 22, cy + 30], 6, fill=t["primary"]),
                                             b.text(cx + 34, cy + 4, "notes.md", 13, weight=500), b.text(cx + 34, cy + 24, "→ atlas-server", 11, t["onSurfaceVariant"]), b.state(cx, cy, 150, 44, 12, s))),
            ("Station (gauge)", lambda cx, cy, s: (b.d.ellipse([cx + 8, cy + 8, cx + 36, cy + 36], fill=t["primary"] if s == "selected" else None, outline=b.t["outlineStrong"]),
                                                   b.d.ellipse([cx, cy, cx + 44, cy + 44], outline=t["primary"], width=2) if s == "selected" else None, b.state(cx, cy, 44, 44, 22, s)))]
    for i, (name, draw) in enumerate(rows):
        ry = y + 40 + i * 80; b.text(x, ry + 12, name, 15, weight=500)
        for j, s in enumerate(STATES): draw(x + 200 + j * 170, ry, s)
    b.text(x, H - PAD - 48, "hover: onSurface 8 % · pressed: onSurface 12 % · focus-visible: 2 px primary ring, 2 px offset · disabled: 38 % content, no pointer", 12, t["onSurfaceVariant"], mono=True)
    b.text(x, H - PAD - 28, "selected: primary fill + onPrimary text (chip, switch, station) or surfaceContainerHigh (row) · motion: hover 100 ms, press 100 ms, OutCubic", 12, t["onSurfaceVariant"], mono=True)
    return b


SCREENS = {"01-map": lambda t: map_screen(t), "02-send": lambda t: send_screen(t), "03-settings": lambda t: settings_screen(t),
           "04-peer-card-long-names": lambda t: map_screen(t, long=True), "05-wizard-key": lambda t: wizard_screen(t, 2), "05-wizard-qr": lambda t: wizard_screen(t, 3),
           "06-diagnosis": diagnosis_screen, "07-tags": tags_screen, "08-states": states_screen,
           "e1-empty-network": lambda t: map_screen(t, card=False, empty=True), "e2-netbird-missing": firstrun_screen,
           "e2-netbird-stopped": lambda t: send_screen(t, signal="stop"), "e3-send-refused": lambda t: send_screen(t, refused=True),
           "e4-30-peers": lambda t: map_screen(t, peers=MANY, card=False), "e5-long-names-send": lambda t: send_screen(t, long=True)}

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "option-a")
    for theme, t in (("dark", DARK), ("light", LIGHT)):
        os.makedirs(os.path.join(out, theme), exist_ok=True)
        for name, fn in SCREENS.items():
            fn(t).im.save(os.path.join(out, theme, name + ".png"))
    # every surface a control can sit on (README §5): text ≥ 4.5:1, borders ≥ 3:1
    print("theme surface                  onSurface variant primary outline outlineStrong")
    for theme, t in (("dark", DARK), ("light", LIGHT)):
        for s in ("surface", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest"):
            c = lambda a: contrast(t[a] if a in t else OUTLINE_STRONG[t["isLightMode"]], t[s])
            print(f"{theme:5} {s:24} {c('onSurface'):9.1f} {c('onSurfaceVariant'):7.1f} {c('primary'):7.1f} {c('outline'):7.2f} {c('outlineStrong'):7.2f}")
