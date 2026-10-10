#!/usr/bin/env python3
"""Builds the Darwin model sheet (front, three-quarter, profile, swimming) as SVG.

Geometry is in the 729 px wide space of the picture the widget uses today,
so the drawing can replace it without touching the scale in Goldfish.qml.
Colours were sampled from the reference frames (see README.md).
"""
import math
import sys

INK, BODY, LIGHT, WHITE = "#0a0a0a", "#f47e26", "#f6bc8c", "#e4e3e8"
BAND = "#d9641c"  # sampled on the swimming frame, tail base
STROKE = 7  # outline weight measured on the reference, in this space

# Silhouette, clockwise from the snout: 48 rays cast every 7.5 degrees from
# (385, 240) onto the reference outline, inset by half the stroke. The four
# points hidden behind the tail fin are interpolated.
BODY_PTS = [(712, 240), (723, 284), (717, 329), (701, 371), (670, 405), (635, 431), (593, 448),
            (553, 459), (517, 468), (480, 469), (446, 468), (415, 469), (385, 468), (355, 469),
            (324, 468), (290, 469), (253, 468), (211, 467), (168, 457), (118, 432), (82, 394),
            (62, 352), (55, 314), (58, 283), (54, 240), (62, 198), (79, 158), (105, 124),
            (136, 96), (169, 74), (203, 58), (236, 45), (267, 35), (296, 26), (326, 19), (355, 11),
            (385, 8), (416, 6), (448, 7), (479, 12), (510, 23), (537, 41), (561, 64), (581, 90),
            (596, 118), (606, 148), (644, 171), (684, 201)]


def smooth(pts):
    """Closed Catmull-Rom spline through pts, written as cubic Beziers."""
    n = len(pts)
    d = "M%d %d" % pts[0]
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += "C%.1f %.1f %.1f %.1f %d %d" % (c1 + c2 + p2)
    return d + "Z"


def blob(pts):
    """Closed smooth shape through every other measured point (brows): the
    6 px reading step of the ink would otherwise show as facets."""
    return smooth(pts[::2])


def chain(pts):
    """Open Catmull-Rom spline through points measured on the reference."""
    d = "M%d %d" % pts[0]
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, len(pts) - 1)]
        d += "C%.1f %.1f %.1f %.1f %d %d" % (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6,
                                             p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1])
    return d


def radial(pts, centre, a0, harmonics, xs=lambda x: x):
    """The measured rays as a smooth closed curve: the 48 radii are a periodic
    function of the angle, and keeping only its low harmonics removes the 1 px
    wobble of the measurement. Returns the curve as a function of t (turns)."""
    n = len(pts)
    r = [math.hypot(x - centre[0], y - centre[1]) for x, y in pts]
    co = [(sum(r[i] * math.cos(2 * math.pi * k * i / n) for i in range(n)) * (1 if k == 0 else 2) / n,
           sum(r[i] * math.sin(2 * math.pi * k * i / n) for i in range(n)) * 2 / n) for k in range(harmonics + 1)]

    def at(t):
        """Point and derivative at parameter t (turns), xs applied to x."""
        rad = sum(a * math.cos(2 * math.pi * k * t) + b * math.sin(2 * math.pi * k * t) for k, (a, b) in enumerate(co))
        drad = sum(2 * math.pi * k * (b * math.cos(2 * math.pi * k * t) - a * math.sin(2 * math.pi * k * t))
                   for k, (a, b) in enumerate(co))
        th = math.radians(a0) + 2 * math.pi * t
        x, y = centre[0] + rad * math.cos(th), centre[1] + rad * math.sin(th)
        dx = drad * math.cos(th) - 2 * math.pi * rad * math.sin(th)
        dy = drad * math.sin(th) + 2 * math.pi * rad * math.cos(th)
        e = 1e-3  # xs is piecewise linear: its slope is read numerically
        return xs(x), y, dx * (xs(x + e) - xs(x - e)) / (2 * e), dy

    return at


def outline(pts, centre, a0, harmonics, xs=lambda x: x):
    """Path of the smooth outline: 24 anchors with analytic tangents give one
    continuous curve with no corner (see README, Smoothness)."""
    at = radial(pts, centre, a0, harmonics, xs)
    m = 24
    p = [at(i / m) for i in range(m + 1)]
    d = "M%.1f %.1f" % p[0][:2]
    for a, b in zip(p, p[1:]):
        d += "C%.1f %.1f %.1f %.1f %.1f %.1f" % (a[0] + a[2] / (3 * m), a[1] + a[3] / (3 * m),
                                                 b[0] - b[2] / (3 * m), b[1] - b[3] / (3 * m), b[0], b[1])
    return d + "Z"


# Front brows: top then bottom edge of each ink blob of the reference, read
# every 6 px where the printed line is half covered (red channel under 125).
BROW_L = [(220, 70), (226, 61), (232, 56), (238, 54), (244, 51), (250, 49), (256, 47), (262, 46), (268, 46),
          (274, 46), (280, 47), (286, 48), (292, 50), (298, 52), (302, 59), (302, 61), (298, 68), (292, 71),
          (286, 71), (280, 70), (274, 69), (268, 68), (262, 69), (256, 71), (250, 73), (244, 75), (238, 79),
          (232, 81), (226, 80), (220, 73)]
BROW_R = [(458, 41), (464, 34), (470, 33), (476, 32), (482, 32), (488, 32), (494, 32), (500, 33), (506, 35),
          (512, 37), (518, 40), (524, 43), (530, 48), (533, 54), (533, 58), (530, 63), (524, 66), (518, 65),
          (512, 63), (506, 60), (500, 57), (494, 55), (488, 54), (482, 54), (476, 54), (470, 55), (464, 55),
          (458, 47)]
# Swimming low fin: centre of the ink line of the reference, read every 8 px.
SWIM_FIN = [(146, 350), (138, 366), (136, 382), (139, 396), (145, 408), (151, 420), (158, 429), (165, 436),
            (177, 444), (192, 452), (205, 455), (217, 452), (230, 444), (238, 434), (250, 410)]


def cheek(cx, cy, r, a1, a2, sweep):
    """Cheek bump: a body-coloured disc that overlaps the eye, outlined on
    the arc from angle a1 to a2 (degrees, y down), open on the outer side."""
    x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
    x2, y2 = cx + r * math.cos(math.radians(a2)), cy + r * math.sin(math.radians(a2))
    return ('<circle cx="%d" cy="%d" r="%d" fill="%s"/>' % (cx, cy, r, BODY)
            + '<path d="M%.1f %.1fA%d %d 0 1 %d %.1f %.1f" fill="none" stroke="%s" stroke-width="%d" stroke-linecap="round"/>'
            % (x1, y1, r, r, sweep, x2, y2, INK, STROKE))


# Tail fin, measured on the reference: it is fused to the body (drawn over the
# body outline, open on the body side), the body line curls a little way into
# it at both ends, and it carries two short strokes.
FIN = [(56, 309), (40, 306), (26, 310), (18, 317), (6, 326), (-3, 340), (-4, 360), (-6, 385), (-2, 410), (6, 428),
       (14, 448), (26, 462), (40, 472), (52, 482), (70, 486), (88, 482), (102, 479), (112, 472), (118, 467),
       (124, 462), (130, 457), (134, 452)]
FIN_CURLS = [[(56, 300), (58, 322), (68, 337)], [(113, 431), (122, 443), (136, 453)]]
CENTRE, HALF_WIDTH, BACK = (385, 240), 335, 54
# Profile tail fin (deduced): the same rounded paddle, seen side-on, so it
# leaves the back of the body along its axis instead of sitting beside it. Its
# size is the swimming fin's (115 x 105 in the 680 space, body 460 wide) carried
# to this space (x 670 / 460). It is drawn under the body, whose line stays
# whole across the root; the first and last two points are hidden there.
FIN_SIDE = [(110, 396), (72, 356), (22, 326), (-36, 314), (-78, 340), (-90, 394), (-80, 446), (-42, 476),
            (16, 472), (76, 450), (122, 432)]
# Turned views are deduced, not traced (no reference shows them): the body is
# taken as 0.6 times as deep as it is wide, turned about its vertical axis.
DEPTH = 0.6
YAW = {"front": 0, "three-quarter": 40, "profile": 90}


def right_edge(at, y):
    """Rightmost x of a closed curve at height y (2000 samples, 1.5 px band)."""
    return max(p[0] for p in (at(i / 2000) for i in range(2000)) if abs(p[1] - y) < 1.5)


# Face parts of the turned views stay this far inside the body line, measured
# along x: a full stroke width of body shows on a horizontal line, 5.5 to 6 px
# across the line where it slants.
INSET = 2 * STROKE


def lashes(cx, cy, rx, ry, angles):
    """Short ticks leaving the eye outline at the given angles (degrees)."""
    d = ""
    for a in angles:
        c, n = math.cos(math.radians(a)), math.sin(math.radians(a))
        d += "M%.1f %.1fL%.1f %.1f" % (cx + (rx + 4) * c, cy + (ry + 4) * n, cx + (rx + 18) * c, cy + (ry + 18) * n)
    return d


def front(small=False, view="front"):
    yaw = math.radians(YAW[view])
    # Apparent width of an ellipsoid turned by yaw, as a share of its width.
    k = math.hypot(math.cos(yaw), DEPTH * math.sin(yaw))

    def xs(x):
        """Silhouette: narrowed toward the tail side, the fin keeps its size."""
        return x if x < BACK else BACK + (x - BACK) * k

    def face(x):
        """A point of the face, on the front surface of the turned body:
        returns its new x and the local horizontal squeeze."""
        u = max(-0.98, min(0.98, (x - CENTRE[0]) / HALF_WIDTH))
        bulge = 0.55 * DEPTH * HALF_WIDTH * math.sin(yaw)  # 0.55: keeps the far eye inside the outline
        return (xs(CENTRE[0]) + u * HALF_WIDTH * math.cos(yaw) + bulge * math.sqrt(1 - u * u),
                math.cos(yaw) - bulge * u / (HALF_WIDTH * math.sqrt(1 - u * u)))

    def fx(pts):
        return [(face(x)[0], y) for x, y in pts]

    s = 'stroke="%s" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round"' % (INK, STROKE)
    leg = '<path d="M%.1f 455v104a35 35 0 0 0 70 0v-104z" fill="%s" %s/>'
    fin = [(xs(x), y) for x, y in FIN]
    body = '<path d="%s" fill="%s" %s/>' % (outline(BODY_PTS, CENTRE, 0, 12, xs), BODY, s)
    shine = ('<path transform="translate(%.1f 0)" d="M112 146c-30 36-36 96-24 140 6 4 14 2 16-6 4-50 18-90 36-122 0-10-18-18-28-12z"'
             ' fill="%s"/>' % (xs(112) - 112, LIGHT))
    # Far leg first: the near one overlaps it when the body turns. In profile
    # both legs are on the view axis: the far one only shows behind the near.
    legs = (xs(CENTRE[0]) - 57, xs(CENTRE[0]) - 35) if view == "profile" else (xs(470), xs(230))
    if view == "profile":
        base = [
            leg % (legs[0], BODY, s), leg % (legs[1], BODY, s),
            '<path d="%s" fill="%s" %s/>' % (smooth(FIN_SIDE), BODY, s),
            body, shine,
        ]
        # Two fin strokes, as on the references, pointing at the root.
        detail = ['<path d="M-86 372l36 6M-66 458l30-22" fill="none" %s/>' % s]
    else:
        base = [
            leg % (legs[0], BODY, s), leg % (legs[1], BODY, s),
            body,
            '<path d="M%.1f %.1f%s" fill="%s" %s/>' % (fin[0] + ("".join(
                "C" + " ".join("%.1f %.1f" % p for p in fin[i:i + 3]) for i in range(1, len(fin), 3)), BODY, s)),
            shine,
        ]
        curls = "".join("M%.1f %dQ%.1f %d %.1f %d" % tuple(v for x, y in c for v in (xs(x), y)) for c in FIN_CURLS)
        detail = ['<path d="%sM3 387l32-6M26 452l32-21" fill="none" %s/>' % (curls, s)]
    thin = s.replace('"7"', '"5"')
    if view == "front":
        detail += [
            '<ellipse cx="269.5" cy="184.5" rx="96" ry="90" fill="%s" %s/>' % (WHITE, s),
            '<ellipse cx="495.5" cy="173" rx="90" ry="86.5" fill="%s" %s/>' % (WHITE, s),
            '<circle cx="285" cy="188" r="47" fill="%s"/><circle cx="484" cy="177" r="47" fill="%s"/>' % (INK, INK),
            # Lashes: short, thin ticks on the upper outer arc of each eye.
            '<path d="M193 124l-10-12M180 147l-12-7M175 171l-13-3M555 99l8-11M575 119l10-7M586 142l12-4" fill="none" %s/>' % thin,
            # Brows are solid shapes on the reference, traced from its ink.
            '<path d="%s%s" fill="%s"/>' % (blob(BROW_L), blob(BROW_R), INK),
            cheek(286, 314, 63, 203, 118, 1), cheek(503, 301, 59, -30, 62, 0),
            '<path d="M346 320Q398 352 448 306" fill="none" %s/>' % s,
            '<circle cx="290" cy="307" r="30" fill="%s"/><circle cx="492" cy="297" r="30" fill="%s"/>' % (LIGHT, LIGHT),
        ]
    elif view == "three-quarter":
        # Every face part of the front view, moved onto the turned surface:
        # the near eye keeps almost its width, the far one narrows.
        (lx, lk), (rx, rk) = face(269.5), face(495.5)
        # The far eye is pulled back until it clears the body line over its
        # whole height; its pupil, brow and cheek move with it.
        at = radial(BODY_PTS, CENTRE, 0, 12, xs)
        far = min(0, min(right_edge(at, y) - INSET - rx - 90 * rk * math.sqrt(1 - ((y - 173) / 86.5) ** 2)
                         for y in range(90, 260, 5)))
        rx += far
        detail += [
            '<ellipse cx="%.1f" cy="184.5" rx="%.1f" ry="90" fill="%s" %s/>' % (lx, 96 * lk, WHITE, s),
            '<ellipse cx="%.1f" cy="173" rx="%.1f" ry="86.5" fill="%s" %s/>' % (rx, 90 * rk, WHITE, s),
            '<ellipse cx="%.1f" cy="188" rx="%.1f" ry="47" fill="%s"/>' % (face(285)[0] + 6, 47 * lk, INK),
            '<ellipse cx="%.1f" cy="177" rx="%.1f" ry="47" fill="%s"/>' % (face(484)[0] + 4 + far, 47 * rk, INK),
            # The far eye's lashes are on the side turned away: hidden. The far
            # brow wraps round the head and stops at the body line.
            '<path d="%s" fill="none" %s/>' % (lashes(lx, 184.5, 96 * lk, 90, (215, 195, 178)), thin),
            '<clipPath id="body"><path d="%s"/></clipPath>' % outline(BODY_PTS, CENTRE, 0, 12, xs),
            '<path d="%s" fill="%s"/><path d="%s" fill="%s" clip-path="url(#body)"/>'
            % (blob(fx(BROW_L)), INK, blob([(x + far, y) for x, y in fx(BROW_R)]), INK),
            cheek(face(286)[0], 314, 63, 203, 118, 1), cheek(face(503)[0] + far, 301, 50, -30, 62, 0),
            '<path d="M%.1f 320Q%.1f 352 %.1f 306" fill="none" %s/>' % (face(346)[0], face(398)[0], face(448)[0], s),
            '<circle cx="%.1f" cy="307" r="30" fill="%s"/>' % (face(290)[0], LIGHT),
            '<ellipse cx="%.1f" cy="297" rx="%.1f" ry="30" fill="%s"/>' % (face(492)[0] + far, 30 * max(rk, 0.7), LIGHT),
        ]
    else:
        # Profile: one eye, one cheek. The eye keeps its height and takes the
        # body's own narrowing (DEPTH). The mouth is the near half of the front
        # smile: it leaves the corner under the cheek and runs out to the body
        # line at the snout, where the front smile is lowest (y 336).
        at = radial(BODY_PTS, CENTRE, 0, 12, xs)
        erx = 96 * DEPTH
        # The eye sits as far forward as the body line allows over its whole
        # height, the brow likewise over its own.
        ex = min(right_edge(at, y) - INSET - erx * math.sqrt(1 - ((y - 184.5) / 90) ** 2)
                 for y in range(100, 270, 5))
        brow = [(ex + (x - 269.5) * DEPTH, y) for x, y in BROW_L]
        back = min(0, min(right_edge(at, y) - INSET - x for x, y in brow))
        brow = [(x + back, y) for x, y in brow]
        detail += [
            '<ellipse cx="%.1f" cy="184.5" rx="%.1f" ry="90" fill="%s" %s/>' % (ex, erx, WHITE, s),
            '<ellipse cx="%.1f" cy="188" rx="%.1f" ry="47" fill="%s"/>' % (ex + 16, 47 * 0.75, INK),
            '<path d="%s" fill="none" %s/>' % (lashes(ex, 184.5, erx, 90, (215, 195, 178)), thin),
            '<path d="%s" fill="%s"/>' % (blob(brow), INK),
            cheek(ex + 10, 314, 50, 203, 118, 1),
            '<path d="M%.1f 318Q%.1f 344 %.1f 336" fill="none" %s/>'
            % (ex + 58, (ex + 58 + right_edge(at, 336)) / 2 - 8, right_edge(at, 336), s),
            '<circle cx="%.1f" cy="307" r="26" fill="%s"/>' % (ex + 12, LIGHT),
        ]
    return "\n".join(base if small else base + detail)


# Swimming view, in the 680x480 crop of the swimming reference. Body outline:
# 48 rays cast every 7.5 degrees from (370, 230), clockwise from the top, onto
# the reference outline, inset by half the stroke. Rays that leave through the
# leg, the arm or the tail fin (8 of 48) keep the hand-traced radius.
SWIM_PTS = [(370, 55), (393, 55), (416, 59), (437, 67), (455, 82), (470, 100), (489, 111), (529, 108), (555,
            123), (575, 145), (588, 172), (595, 200), (596, 230), (584, 258), (569, 283), (545,
            303), (524, 319), (501, 331), (481, 341), (461, 349), (445, 359), (427, 367), (409,
            374), (390, 381), (370, 387), (348, 396), (324, 403), (296, 409), (266, 411), (237,
            404), (210, 390), (185, 372), (165, 348), (151, 321), (142, 291), (147, 259), (152,
            230), (162, 203), (177, 178), (193, 157), (211, 138), (231, 123), (249, 109), (267, 96),
            (286, 85), (306, 75), (326, 67), (348, 59)]


def swim(small=False):
    s = 'stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"' % INK
    base = [
        # Leg kicked up behind the body.
        '<path d="M520 125C535 70 570 35 620 28c35-3 50 27 30 50-20 17-50 17-65 62" fill="%s" %s/>' % (BODY, s),
        # Darker band where the leg leaves the body, as on the reference.
        '<path d="M524 112l34 22 10-20-36-20z" fill="%s"/>' % BAND,
        '<path d="%s" fill="%s" %s/>' % (outline(SWIM_PTS, (370, 230), -90, 12), BODY, s),
        '<path d="M158 222c-14 20-12 52 4 70 8 4 14-2 12-10-8-18-8-36 0-52-2-8-10-12-16-8z" fill="%s"/>' % LIGHT,
        # Tail fin under the arm, then the arm reaching forward; both open
        # paths so the joint with the body carries no outline.
        '<path d="%s" fill="%s" %s/>' % (chain(SWIM_FIN), BODY, s),
        # Two long strokes across the fin and a tick under the arm, as measured.
        '<path d="M150 405L169 395M181 443L195 423M175 355l6 5" fill="none" %s/>' % s,
        '<path d="M218 318C160 288 92 288 50 320c-35 25-30 65 0 70 35 2 60-25 93-42L197 358" fill="%s" %s/>' % (BODY, s),
    ]
    detail = [
        '<ellipse cx="272.5" cy="217" rx="67" ry="64" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="416.5" cy="156" rx="64" ry="61.5" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="296.5" cy="198.4" r="20.5" fill="%s"/><circle cx="437.6" cy="140.6" r="19.6" fill="%s"/>' % (INK, INK),
        '<path d="M207 200l-12-4M205 220l-13 3M432 96l2-12M452 102l6-11" fill="none" %s/>' % s,
        # Neutral brows: the reference frame frowns, the model sheet does not.
        '<path d="M234 140c16-12 40-16 60-10M372 84c18-12 42-12 58-2" fill="none" %s/>' % s.replace('"5"', '"8"'),
        cheek(310, 298, 43, 189, 96, 1).replace('width="7"', 'width="5"'),
        cheek(454, 237, 41, -64, 49, 0).replace('width="7"', 'width="5"'),
        '<path d="M353 282Q384 266 413 259" fill="none" %s/>' % s,
        '<circle cx="314" cy="291" r="18" fill="%s"/><circle cx="443" cy="235" r="19" fill="%s"/>' % (LIGHT, LIGHT),
    ]
    return "\n".join(base if small else base + detail)


def optical(view, w, h, box, base, snapped):
    """25 px wide variant for the real widget size: the silhouette is the
    drawing scaled down, the parts that would fall between pixels (eyes,
    pupils, cheeks, legs) are redrawn on whole pixels, and the lashes, brows
    and mouth, thinner than a third of a pixel there, are left out."""
    k = 25 / box[2]  # box[2]: the width that maps to 25 px, the same for every view of one space
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">\n'
            '<title>Darwin, %s, 25 px optical size</title>\n'
            '<g transform="scale(%.5f) translate(%d %d)">\n%s\n</g>\n%s\n</svg>\n'
            % (w, h, w, h, view, k, -box[0], -box[1], base, snapped))


def px(x, y, w, h, fill, r=0):
    return '<rect x="%d" y="%d" width="%d" height="%d" rx="%s" fill="%s"/>' % (x, y, w, h, r, fill)


FRONT_25 = "".join([px(8, 15, 2, 5, BODY, 1), px(16, 15, 2, 5, BODY, 1),
                    px(6, 3, 6, 6, WHITE, 3), px(14, 3, 6, 6, WHITE, 3),
                    px(8, 5, 3, 3, INK, 1), px(15, 5, 3, 3, INK, 1),
                    px(9, 10, 2, 2, LIGHT, 1), px(16, 10, 2, 2, LIGHT, 1)])
# Turned views at the front view's scale (25 / 745): 22 and 17 px wide. One
# pixel of body is kept between the two eyes of the three-quarter view.
THREE_QUARTER_25 = "".join([px(7, 15, 2, 5, BODY, 1), px(14, 15, 2, 5, BODY, 1),
                            px(8, 3, 5, 6, WHITE, 2.5), px(14, 3, 4, 6, WHITE, 2),
                            px(10, 5, 3, 3, INK, 1), px(15, 5, 2, 3, INK),
                            px(11, 10, 2, 2, LIGHT, 1), px(15, 10, 1, 2, LIGHT)])
# Profile: its box starts 89 units further left for the fin, 3 px here.
PROFILE_25 = "".join([px(10, 15, 2, 5, BODY, 1), px(11, 15, 2, 5, BODY, 1),
                      px(12, 3, 4, 6, WHITE, 2), px(14, 5, 2, 3, INK), px(14, 10, 2, 2, LIGHT, 1)])
# One pixel of body is kept between the two eyes so they do not merge; the
# pupils are square so that they stay solid ink on whole pixels.
SWIM_25 = "".join([px(7, 5, 5, 5, WHITE, 2.5), px(13, 3, 5, 5, WHITE, 2.5),
                   px(10, 6, 2, 2, INK), px(15, 4, 2, 2, INK),
                   px(11, 10, 1, 1, LIGHT), px(16, 8, 1, 1, LIGHT)])


if __name__ == "__main__":
    out = sys.argv[1]
    open(out + "/darwin-front.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 -8 745 612" width="745" height="612">\n'
        '<title>Darwin, front view, neutral pose</title>\n%s\n</svg>\n' % front())
    for name, left, width in (("three-quarter", -12, 660), ("profile", -101, 566)):
        open(out + "/darwin-%s.svg" % name, "w").write(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%d -8 %d 612" width="%d" height="612">\n'
            '<title>Darwin, %s view, neutral pose (deduced from the front view)</title>\n%s\n</svg>\n'
            % (left, width, width, name, front(view=name)))
    open(out + "/darwin-swim.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 480" width="680" height="480">\n'
        '<title>Darwin, side view, swimming</title>\n%s\n</svg>\n' % swim())
    open(out + "/darwin-front-25.svg", "w").write(optical("front view", 25, 21, (-12, -8, 745), front(True), FRONT_25))
    open(out + "/darwin-three-quarter-25.svg", "w").write(
        optical("three-quarter view", 22, 21, (-12, -8, 745), front(True, "three-quarter"), THREE_QUARTER_25))
    open(out + "/darwin-profile-25.svg", "w").write(
        optical("profile view", 19, 21, (-101, -8, 745), front(True, "profile"), PROFILE_25))
    open(out + "/darwin-swim-25.svg", "w").write(optical("swimming view", 25, 18, (0, 0, 680), swim(True), SWIM_25))
