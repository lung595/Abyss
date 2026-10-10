#!/usr/bin/env python3
"""Real-size PNG mockups of the Abyss app v1 screens (NAK-286, option A).

Not production code. Reuses the palette, fonts and drawing helpers of the
direction wireframes (`../render.py`) so every value comes from the same
token list (mockups/README.md §5). Fictional data only. No browser exists on
the machine (Q104), so these PNGs are what the owner reviews; the HTML files
stay the interactive reference. Run: python3 render.py [outdir]
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from render import Board, DARK, LIGHT, PEERS, LONG, font, contrast  # noqa: E402
from PIL import ImageFont  # noqa: E402

# NotoSans has no geometric symbols: pick the Noto face that owns each glyph
SYMBOL_FONTS = {"/usr/share/fonts/google-noto/NotoSansSymbols2-Regular.ttf": "\u25cf\u25cb\u25d0\u2605\u2715\u26a0\u25c9\u2316\u263c\u2318\u2022",
                "/usr/share/fonts/google-noto-vf/NotoSansSymbols[wght].ttf": "\u266a\u2691"}

W, H, GAUGE, PAD, TITLE = 1280, 800, 72, 32, 44
OPTION_B = "--option-b" in sys.argv  # stacked column, light falling off in 8 flat bands
STATIONS = [("Settings", 0, "surfaceContainerHighest", "surfaceContainerLowest"),
            ("Send", 200, "surfaceContainer", "surfaceContainerLow"),
            ("Map", 4000, "surfaceContainerLowest", "surfaceContainerHigh")]
MANY = [(f"{n}-{k}", k, 5 + i * 7, i % 5 != 4) for i, (n, k) in enumerate(
    zip("atlas harbor nova reef kite pi dune orca coral tide brine kelp moss gull wave foam silt drift shoal delta fjord lagoon buoy mast keel helm reef2 cove bay".split(),
        ("ray whale fish turtle horse squid nautilus".split() * 5)))][:30]


class App(Board):
    """One 1280×800 window: depth gauge + one flat stratum per station."""

    def glyph(self, x, y, ch, size=13, color=None, anchor="la"):
        """Draw one symbol with a font that really has it (arrows live in the mono face)."""
        path = next((f for f, chars in SYMBOL_FONTS.items() if ch in chars), None)
        f = ImageFont.truetype(path, size) if path else font(size, 400, True)
        self.d.text((x, y), ch, fill=color or self.t["onSurface"], font=f, anchor=anchor)

    def chip(self, x, y, s, on=False, w=None, close=False):
        """Board.chip plus an optional ✕ (44 px hit) drawn with the symbol font."""
        w = Board.chip(self, x, y, s + ("     " if close else ""), on, w)
        if close: self.glyph(x + w - 22, y + 16, "\u2715", 12, self.t["onPrimary"] if on else self.t["onSurface"], "mm")
        return w

    def __init__(self, t, station, signal="ok"):
        super().__init__(W, H, t)
        self.station, self.signal = station, signal
        name, depth, dark, light = STATIONS[station]
        self.rect(GAUGE, 0, W - GAUGE, H, fill=t[light if t["isLightMode"] else dark], r=0)
        if OPTION_B and station:  # 8 flat bands from the stratum above to this one
            a, b = (t[STATIONS[station - 1][3 if t["isLightMode"] else 2]], t[light if t["isLightMode"] else dark])
            for i in range(8):
                k = i / 7; c = "#%02x%02x%02x" % tuple(round(int(a[j:j + 2], 16) * (1 - k) + int(b[j:j + 2], 16) * k) for j in (1, 3, 5))
                self.rect(GAUGE, i * H // 8, W - GAUGE, H // 8 + 1, fill=c, r=0)
        self.gauge(depth)
        self.text(GAUGE + PAD, 36, name, 22, weight=600)
        self.text(GAUGE + PAD + self.d.textlength(name, font=font(22, 600)) + 12, 44,
                  f"· {depth:,} m".replace(",", " "), 13, t["onSurfaceVariant"], mono=True)

    def gauge(self, depth):
        t = self.t
        self.rect(0, 0, GAUGE, H, fill=t["surfaceContainer"], r=0)
        self.d.line([(GAUGE - 1, 0), (GAUGE - 1, H)], fill=t["outline"])
        top, bottom = 40, 560  # scale: 0 m at top, 4 000 m at bottom
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
                self.d.ellipse([10, y - 14, 38, y + 14], outline=t["outline"], width=1)
        # instrument readouts (mono, tabular): the glyph changes with the state, never colour alone
        glyph, col = {"ok": ("●", "success"), "warn": ("◐", "warning"), "stop": ("○", "error")}[self.signal]
        temp = {0: 18, 200: 6, 4000: 2}[depth]
        for j, (s, c) in enumerate([(f"{depth:>5} m", "onSurface"), (f"{depth / 10 + 1:>5.0f} bar", "onSurfaceVariant"),
                                    (f"{temp:>5} °C", "onSurfaceVariant"), (f"{glyph} signal", col)]):
            self.text(8, 620 + j * 20, s, 11, t[c], mono=True)  # mono face owns ●◐○

    def darwin(self, x, y):
        """The small fish mascot hanging beside the current station (24 px)."""
        c = self.t["secondary"]
        self.d.polygon([(x, y), (x + 14, y - 7), (x + 14, y + 7)], fill=c)
        self.d.polygon([(x + 14, y), (x + 24, y - 6), (x + 24, y + 6)], fill=c)

    # ---- bands and guided messages (values 10) ----
    def band(self, y, msg, kind="warning", action=None, guide=False):
        t = self.t; x, w = GAUGE + PAD, W - GAUGE - 2 * PAD
        self.rect(x, y, w, 44, fill=t[kind] + "21", outline=t[kind], r=12)
        self.glyph(x + 16, y + 14, "\u26a0" if kind == "warning" else "\u2715", 13, t[kind]); self.text(x + 36, y + 14, msg, 13, t["onSurface"], 500)
        ax = x + w - 16
        if guide:  # GitHub mark → docs/GUIDE.md anchor, opened on click only
            self.d.ellipse([ax - 24, y + 10, ax, y + 34], fill=t["onSurface"]); self.text(ax - 12, y + 22, "G", 12, t["surface"], 700, anchor="mm"); ax -= 36
        if action:
            w2 = int(self.d.textlength(action, font=font(13, 600))) + 24
            self.rect(ax - w2, y + 6, w2, 32, fill=t[kind], r=16); self.text(ax - w2 + 12, y + 14, action, 13, t["onSurface" if t["isLightMode"] else "surface"], 600)

    def panel(self, title, h=480):
        t = self.t; x, y = (W + GAUGE) // 2 - 280, (H - h) // 2
        self.rect(GAUGE, 0, W - GAUGE, H, fill=t["surface"] + "99", r=0)
        self.rect(x, y, 560, h, fill=t["surfaceContainer"], outline=t["outline"], r=20)
        self.text(x + 24, y + 22, title, 22, weight=600); self.glyph(x + 524, y + 34, "\u2715", 18, t["onSurfaceVariant"], "mm")
        return x, y


def sparkline(b, x, y, w, h, seed=3):
    pts = [(x + i * w // 23, y + h - 2 - ((i * seed * 7) % (h - 4))) for i in range(24)]
    b.d.line(pts, fill=b.t["primary"], width=2)


# ---------------- screens ----------------
def map_screen(t, peers=PEERS, card=True, empty=False, long=False, signal="ok"):
    b = App(t, 2, signal); x, y, w, h = GAUGE + PAD, PAD + TITLE + 8, W - GAUGE - 2 * PAD, H - PAD * 2 - TITLE - 48
    b.rect(x, y, w, h, fill=t["surfaceContainerLowest"] if not t["isLightMode"] else t["surfaceContainerHigh"], outline=t["outline"], r=16)
    cx = x + 120; b.chip(x + 16, y + 16, "All", True); cx += 20
    for s in ("#servers", "#home", "lab"): cx += b.chip(cx, y + 16, s) + 8
    for i, g in enumerate("+ − ⌖"): b.rect(x + w - 60, y + 16 + i * 48, 44, 44, outline=t["outline"], r=12); b.glyph(x + w - 38, y + 38 + i * 48, g, 18, anchor="mm")
    b.jelly(x + w // 2, y + 120)
    if empty:
        b.text(x + w // 2, y + 300, "No creature yet", 22, weight=600, anchor="ma")
        b.text(x + w // 2, y + 336, "Add a device from the + at the top right, or wait: NetBird is listening.", 13, t["onSurfaceVariant"], anchor="ma")
    else:
        if len(peers) > 8:  # 30 peers: caves per group + compact list under the sea
            for k, (gname, n) in enumerate([("servers", 9), ("home", 8), ("lab", 7), ("other", 6)]):
                gx = x + 200 + k * 220; b.d.ellipse([gx - 70, y + 330, gx + 70, y + 420], outline=t["outline"], width=1)
                b.text(gx, y + 362, gname, 15, weight=600, anchor="ma"); b.text(gx, y + 386, f"{n} creatures", 13, t["onSurfaceVariant"], mono=True, anchor="ma")
            for i, (n, k, ms, on) in enumerate(peers[:24]):
                b.text(x + 16 + (i % 6) * 190, y + h - 70 + (i // 6) * 16, ("\u25cf " if on else "\u25cb ") + n, 11, t["onSurface"] if on else t["onSurfaceVariant"], mono=True)
        else:
            for i, (n, k, ms, on) in enumerate(peers):
                px, py = x + 120 + (i % 4) * 250, y + 240 + (i // 4) * 200
                b.creature(px, py, LONG[:14] + "…" + LONG[-9:] if long and i == 0 else n, k, on)
        if card:
            px, py = x + w - 76 - 300, y + 80
            b.rect(px, py, 300, 240, fill=t["surfaceContainer"], outline=t["outline"], r=16)
            b.text(px + 16, py + 16, (LONG[:12] + "…" + LONG[-8:]) if long else "atlas-server", 15, weight=600)
            b.text(px + 16, py + 40, "100.64.0.12 · 12 ms · 9 d", 13, t["onSurfaceVariant"], mono=True)
            sparkline(b, px + 16, py + 64, 240, 24)
            b.glyph(px + 16, py + 98, "\u25cf", 13, t["success"]); b.text(px + 32, py + 98, "Direct · 12 ms · healthy", 13, t["success"], 500)
            bx = px + 16; bx += b.chip(bx, py + 128, "Send a file", True) + 8; bx += b.chip(bx, py + 128, "Browse files") + 8; b.chip(bx, py + 128, "SSH")
            b.chip(px + 16, py + 172, "    Favourite"); b.glyph(px + 36, py + 188, "\u2605", 13, anchor="mm"); b.chip(px + 140, py + 172, "Diagnosis")
    b.text(x, H - PAD - 16, "8/10 online · ↓ 21 Mb/s · ↑ 4.3 Mb/s", 13, t["onSurfaceVariant"], mono=True)
    if signal == "stop": b.band(H - PAD - 60, "NetBird is stopped: creatures are asleep.", "warning", "Start NetBird")
    return b


def send_screen(t, refused=False, long=False, signal="ok"):
    b = App(t, 1, signal); x, y, w = GAUGE + PAD, PAD + TITLE + 8, W - GAUGE - 2 * PAD
    b.rect(x, y, w, 120, outline=t["primary"], r=16); b.d.rounded_rectangle([x + 8, y + 8, x + w - 9, y + 111], 12, outline=t["outline"] + "88")
    b.text(x + w // 2, y + 44, "Drop files here, or press Ctrl+O", 15, t["onSurfaceVariant"], 500, anchor="ma")
    b.text(x, y + 148, "To", 13, t["onSurfaceVariant"]); cx = x + 40
    for s, on in (("atlas-server", True), ("reef-nas", True), (("a-very-long-device-name-that…" if long else "nova-laptop"), False)): cx += b.chip(cx, y + 136, s, on) + 8
    rows = [("quarterly-report-final-v3.pdf", "atlas-server", 42, "8.1 MB/s", "Cancel"), ("holiday-photos-2026.tar", "reef-nas", None, "scp · no progress", "Cancel"),
            ("notes.md", "atlas-server", 100, "done", "Dismiss")]
    if long: rows[0] = (LONG[:18] + "…" + LONG[-6:] + ".pdf", LONG[:10] + "…", 42, "8.1 MB/s", "Cancel")
    yy = y + 192
    for i, (name, dev, pct, spd, act) in enumerate(rows):
        ry = yy + i * 56; b.d.line([(x, ry + 55), (x + w, ry + 55)], fill=t["outline"] + "66")
        b.d.rounded_rectangle([x + 2, ry + 20, x + 14, ry + 36], 6, fill=t["primary"] if pct != 100 else t["outline"])
        b.text(x + 28, ry + 10, name, 15, weight=500); b.text(x + 28, ry + 32, "→ " + dev, 12, t["onSurfaceVariant"])
        tx = x + w - 500; b.rect(tx, ry + 24, 120, 8, fill=t["surfaceContainerHighest"], r=4)
        if pct is None: b.rect(tx + 40, ry + 24, 36, 8, fill=t["primary"], r=4); b.text(tx + 136, ry + 20, "Sending…", 13, mono=True)
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
    b.rect(x, y, w, 44, fill=t["surfaceContainerLow"] if t["isLightMode"] else t["surfaceContainer"], outline=t["outline"], r=12); b.text(x + 16, y + 13, "Search settings   /", 15, t["onSurfaceVariant"])
    for i, (ic, s) in enumerate([("\u25c9", "Network"), ("\u2193", "Sending"), ("\u263c", "Appearance"), ("\u266a", "Sounds"), ("\u2318", "Shortcuts"), ("\u2691", "Privacy")]):
        on = i == 1; b.rect(x, y + 68 + i * 48, 200, 40, fill=t["primary"] if on else None, r=12)
        b.glyph(x + 20, y + 88 + i * 48, ic, 14, t["onPrimary"] if on else t["onSurface"], "mm"); b.text(x + 40, y + 78 + i * 48, s, 15, t["onPrimary"] if on else t["onSurface"], 600 if on else 500)
    rx = x + 232
    for i, (lab, help_, kind) in enumerate([("Receive folder", "Where files you receive are saved", "~/Downloads/Abyss"), ("Ask before receiving", "A capsule waits for your answer", True),
                                             ("Retry failed sends", "Up to 3 times, 10 s apart", False), ("Parallel transfers", "At most, per device", "2"), ("Play a sound on arrival", "Gentle, rate-limited", True)]):
        ry = y + 68 + i * 72; b.text(rx, ry, lab, 15, weight=500); b.text(rx, ry + 24, help_, 12, t["onSurfaceVariant"])
        if kind is True or kind is False:
            b.rect(x + w - 48, ry + 6, 48, 28, fill=t["primary"] if kind else t["surfaceContainerHighest"], r=14)
            b.d.ellipse([x + w - 48 + (24 if kind else 4), ry + 10, x + w - 48 + (44 if kind else 24), ry + 30], fill=t["onPrimary"] if kind else t["outline"])
        else: b.chip(x + w - 12 - int(b.d.textlength(kind, font=font(13, 500))) - 24, ry + 4, kind)
    return b


def wizard_screen(t, step=2):
    b = map_screen(t, card=False); x, y = b.panel("Add a device")
    for i, s in enumerate(("Name", "Key", "QR code")):
        b.chip(x + 24 + i * 110, y + 64, f"{i + 1} {s}", i == step - 1)
    if step == 2:
        b.text(x + 24, y + 128, "Setup key", 15, weight=500); b.text(x + 24, y + 152, "Paste it on the new device. It is never shown or logged.", 12, t["onSurfaceVariant"])
        b.rect(x + 24, y + 184, 400, 44, fill=t["surfaceContainerHigh"], outline=t["outline"], r=12); b.text(x + 40, y + 196, "••••••••••••••••••••", 15, mono=True)
        b.rect(x + 436, y + 184, 44, 44, outline=t["outline"], r=12); b.glyph(x + 458, y + 206, "\u25c9", 18, anchor="mm")
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
    b.rect(x + 24, y + 120, 240, 44, outline=t["outline"], r=12); b.text(x + 40, y + 132, "New tag…", 15, t["onSurfaceVariant"])
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


SCREENS = {"01-map": lambda t: map_screen(t), "02-send": lambda t: send_screen(t), "03-settings": lambda t: settings_screen(t),
           "04-peer-card-long-names": lambda t: map_screen(t, long=True), "05-wizard-key": lambda t: wizard_screen(t, 2), "05-wizard-qr": lambda t: wizard_screen(t, 3),
           "06-diagnosis": diagnosis_screen, "07-tags": tags_screen,
           "e1-empty-network": lambda t: map_screen(t, card=False, empty=True), "e2-netbird-missing": firstrun_screen,
           "e2-netbird-stopped": lambda t: send_screen(t, signal="stop"), "e3-send-refused": lambda t: send_screen(t, refused=True),
           "e4-30-peers": lambda t: map_screen(t, peers=MANY, card=False), "e5-long-names-send": lambda t: send_screen(t, long=True)}

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "option-b" if OPTION_B else "option-a")
    for theme, t in (("dark", DARK), ("light", LIGHT)):
        os.makedirs(os.path.join(out, theme), exist_ok=True)
        for name, fn in SCREENS.items():
            fn(t).im.save(os.path.join(out, theme, name + ".png"))
    # strata used as text backgrounds (README §5): every pair must pass AA
    for theme, t in (("dark", DARK), ("light", LIGHT)):
        for _, _, dk, lt in STATIONS:
            s = lt if t["isLightMode"] else dk
            print(f"{theme:5} onSurface/{s:24} {contrast(t['onSurface'], t[s]):.1f}:1  variant {contrast(t['onSurfaceVariant'], t[s]):.1f}:1  primary {contrast(t['primary'], t[s]):.1f}:1")
