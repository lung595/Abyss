#!/usr/bin/env python3
"""Builds the Darwin model sheet (front view) as SVG.

Geometry is in the 729 px wide space of the picture the widget uses today,
so the drawing can replace it without touching the scale in Goldfish.qml.
Colours were sampled from the reference frames (see README.md).
"""
import math
import sys

INK, BODY, LIGHT, LIMB, WHITE = "#0a0a0a", "#f47e26", "#f6bc8c", "#f49c52", "#e4e3e8"
STROKE = 7  # outline weight measured on the reference, in this space

# Silhouette, clockwise from the snout; the belly is nearly flat, as on the
# reference.
BODY_PTS = [(722, 260), (723, 317), (704, 371), (666, 414), (618, 443), (568, 460), (510, 468),
            (440, 472), (370, 473), (300, 472), (230, 467), (165, 452), (105, 420), (62, 370),
            (48, 315), (51, 260), (57, 200), (83, 145), (125, 101), (172, 69), (221, 47),
            (268, 31), (312, 18), (356, 9), (400, 3), (445, 4), (490, 12), (532, 31), (566, 62),
            (591, 100), (608, 140), (647, 170), (694, 208)]


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


def cheek(cx, cy, r, a1, a2, sweep):
    """Cheek bump: a body-coloured disc that overlaps the eye, outlined on
    the arc from angle a1 to a2 (degrees, y down), open on the outer side."""
    x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
    x2, y2 = cx + r * math.cos(math.radians(a2)), cy + r * math.sin(math.radians(a2))
    return ('<circle cx="%d" cy="%d" r="%d" fill="%s"/>' % (cx, cy, r, BODY)
            + '<path d="M%.1f %.1fA%d %d 0 1 %d %.1f %.1f" fill="none" stroke="%s" stroke-width="%d" stroke-linecap="round"/>'
            % (x1, y1, r, r, sweep, x2, y2, INK, STROKE))


def front():
    s = 'stroke="%s" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round"' % (INK, STROKE)
    leg = '<path d="M%d 455v104a35 35 0 0 0 70 0v-104z" fill="%s" %s/>'
    return "\n".join([
        leg % (230, BODY, s), leg % (470, BODY, s),
        '<path d="M120 318C70 296 14 316 10 360c-2 14 8 24 22 27c-16 5-26 16-24 32c4 44 44 58 94 53c40-4 66-20 80-40z" fill="%s" %s/>' % (LIMB, s),
        '<path d="M32 387l46 3M24 430l48-10" fill="none" %s/>' % s,
        '<path d="%s" fill="%s" %s/>' % (smooth(BODY_PTS), BODY, s),
        '<path d="M112 146c-30 36-36 96-24 140 6 4 14 2 16-6 4-50 18-90 36-122 0-10-18-18-28-12z" fill="%s"/>' % LIGHT,
        '<ellipse cx="269.5" cy="184.5" rx="96" ry="90" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="495.5" cy="173" rx="90" ry="86.5" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="285" cy="188" r="45" fill="%s"/><circle cx="484" cy="177" r="45" fill="%s"/>' % (INK, INK),
        '<path d="M178 150l-20-8M172 172l-22 0M176 196l-20 10M584 128l20-10M590 150l22-2M590 174l20 6" fill="none" %s/>' % s,
        '<path d="M224 76c16-18 44-26 66-22M460 40c20-6 44 0 60 18" fill="none" %s stroke-opacity="1"/>' % s.replace('"7"', '"11"'),
        cheek(286, 312, 61, 203, 118, 1), cheek(503, 299, 57, -30, 62, 0),
        '<path d="M346 320Q398 352 448 306" fill="none" %s/>' % s,
        '<circle cx="290" cy="307" r="30" fill="%s"/><circle cx="492" cy="297" r="30" fill="%s"/>' % (LIGHT, LIGHT),
    ])


# Swimming view, traced in the 680x480 crop of the swimming reference.
SWIM_PTS = [(380, 48), (430, 56), (462, 80), (484, 106), (508, 104), (545, 116), (580, 150), (598, 200),
            (596, 250), (570, 295), (525, 332), (470, 360), (410, 385), (350, 402), (290, 412),
            (240, 405), (195, 380), (160, 340), (142, 290), (140, 240), (155, 190), (190, 140),
            (240, 100), (300, 68), (340, 54)]


def swim():
    s = 'stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"' % INK
    return "\n".join([
        # Leg kicked up behind the body.
        '<path d="M520 125C535 70 570 35 620 28c35-3 50 27 30 50-20 17-50 17-65 62" fill="%s" %s/>' % (BODY, s),
        '<path d="%s" fill="%s" %s/>' % (smooth(SWIM_PTS), BODY, s),
        '<path d="M158 222c-14 20-12 52 4 70 8 4 14-2 12-10-8-18-8-36 0-52-2-8-10-12-16-8z" fill="%s"/>' % LIGHT,
        # Tail fin under the arm, then the arm reaching forward; both open
        # paths so the joint with the body carries no outline.
        '<path d="M150 352c-28 30-10 80 30 92 36 10 66-6 70-36" fill="%s" %s/>' % (BODY, s),
        '<path d="M158 392l26 12M192 420l14 22" fill="none" %s/>' % s,
        '<path d="M218 318C160 288 92 288 50 320c-35 25-30 65 0 70 35 2 60-25 100-40" fill="%s" %s/>' % (BODY, s),
        '<ellipse cx="275" cy="205" rx="70" ry="56" transform="rotate(-12 275 205)" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="418" cy="155" rx="67" ry="62" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="297" cy="198" r="22" fill="%s"/><circle cx="437" cy="140" r="21" fill="%s"/>' % (INK, INK),
        '<path d="M210 186l-12-4M208 206l-13 3M432 96l2-12M452 102l6-11" fill="none" %s/>' % s,
        # Neutral brows: the reference frame frowns, the model sheet does not.
        '<path d="M236 136c16-12 40-16 60-10M372 84c18-12 42-12 58-2" fill="none" %s/>' % s.replace('"5"', '"8"'),
        cheek(318, 291, 37, 205, 110, 1).replace('width="7"', 'width="5"'),
        cheek(447, 236, 37, -40, 70, 0).replace('width="7"', 'width="5"'),
        '<path d="M354 287C372 292 396 270 412 262" fill="none" %s/>' % s,
        '<circle cx="318" cy="289" r="21" fill="%s"/><circle cx="443" cy="233" r="21" fill="%s"/>' % (LIGHT, LIGHT),
    ])


if __name__ == "__main__":
    out = sys.argv[1]
    open(out + "/darwin-front.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -8 737 612" width="737" height="612">\n'
        '<title>Darwin, front view, neutral pose</title>\n%s\n</svg>\n' % front())
    open(out + "/darwin-swim.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 480" width="680" height="480">\n'
        '<title>Darwin, side view, swimming</title>\n%s\n</svg>\n' % swim())
