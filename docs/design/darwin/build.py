#!/usr/bin/env python3
"""Builds the Darwin model sheet (front view) as SVG.

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


def poly(pts):
    """Closed polygon through points measured on the reference (brows)."""
    return "M" + "L".join("%d %d" % p for p in pts) + "Z"


def chain(pts):
    """Open Catmull-Rom spline through points measured on the reference."""
    d = "M%d %d" % pts[0]
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, len(pts) - 1)]
        d += "C%.1f %.1f %.1f %.1f %d %d" % (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6,
                                             p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1])
    return d


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


def front(small=False):
    s = 'stroke="%s" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round"' % (INK, STROKE)
    leg = '<path d="M%d 455v104a35 35 0 0 0 70 0v-104z" fill="%s" %s/>'
    base = [
        leg % (230, BODY, s), leg % (470, BODY, s),
        '<path d="%s" fill="%s" %s/>' % (smooth(BODY_PTS), BODY, s),
        # Tail fin, measured on the reference: it is fused to the body (drawn
        # over the body outline, open on the body side), the body line curls a
        # little way into it at both ends, and it carries two short strokes.
        '<path d="M56 309C40 306 26 310 18 317C6 326-3 340-4 360C-6 385-2 410 6 428C14 448 26 462 40 472'
        'C52 482 70 486 88 482C102 479 112 472 118 467C124 462 130 457 134 452" fill="%s" %s/>' % (BODY, s),
        '<path d="M112 146c-30 36-36 96-24 140 6 4 14 2 16-6 4-50 18-90 36-122 0-10-18-18-28-12z" fill="%s"/>' % LIGHT,
    ]
    detail = [
        '<path d="M56 300Q58 322 68 337M113 431Q122 443 136 453M3 387l32-6M26 452l32-21" fill="none" %s/>' % s,
        '<ellipse cx="269.5" cy="184.5" rx="96" ry="90" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="495.5" cy="173" rx="90" ry="86.5" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="285" cy="188" r="47" fill="%s"/><circle cx="484" cy="177" r="47" fill="%s"/>' % (INK, INK),
        # Lashes: short, thin ticks on the upper outer arc of each eye.
        '<path d="M193 124l-10-12M180 147l-12-7M175 171l-13-3M555 99l8-11M575 119l10-7M586 142l12-4" fill="none" %s/>' % s.replace('"7"', '"5"'),
        # Brows are solid shapes on the reference, traced from its ink.
        '<path d="%s%s" fill="%s"/>' % (poly(BROW_L), poly(BROW_R), INK),
        cheek(286, 314, 63, 203, 118, 1), cheek(503, 301, 59, -30, 62, 0),
        '<path d="M346 320Q398 352 448 306" fill="none" %s/>' % s,
        '<circle cx="290" cy="307" r="30" fill="%s"/><circle cx="492" cy="297" r="30" fill="%s"/>' % (LIGHT, LIGHT),
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
        '<path d="%s" fill="%s" %s/>' % (smooth(SWIM_PTS), BODY, s),
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


def optical(view, w, h, box, snapped):
    """25 px wide variant for the real widget size: the silhouette is the
    drawing scaled down, the parts that would fall between pixels (eyes,
    pupils, cheeks, legs) are redrawn on whole pixels, and the lashes, brows
    and mouth, thinner than a third of a pixel there, are left out."""
    k = 25 / box[2]
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">\n'
            '<title>Darwin, %s, 25 px optical size</title>\n'
            '<g transform="scale(%.5f) translate(%d %d)">\n%s\n</g>\n%s\n</svg>\n'
            % (w, h, w, h, view, k, -box[0], -box[1], (front if view == "front view" else swim)(True), snapped))


def px(x, y, w, h, fill, r=0):
    return '<rect x="%d" y="%d" width="%d" height="%d" rx="%s" fill="%s"/>' % (x, y, w, h, r, fill)


FRONT_25 = "".join([px(8, 15, 2, 5, BODY, 1), px(16, 15, 2, 5, BODY, 1),
                    px(6, 3, 6, 6, WHITE, 3), px(14, 3, 6, 6, WHITE, 3),
                    px(8, 5, 3, 3, INK, 1), px(15, 5, 3, 3, INK, 1),
                    px(9, 10, 2, 2, LIGHT, 1), px(16, 10, 2, 2, LIGHT, 1)])
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
    open(out + "/darwin-swim.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 480" width="680" height="480">\n'
        '<title>Darwin, side view, swimming</title>\n%s\n</svg>\n' % swim())
    open(out + "/darwin-front-25.svg", "w").write(optical("front view", 25, 21, (-12, -8, 745), FRONT_25))
    open(out + "/darwin-swim-25.svg", "w").write(optical("swimming view", 25, 18, (0, 0, 680), SWIM_25))
