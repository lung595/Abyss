#!/usr/bin/env python3
"""Builds the Darwin model sheet (front view) as SVG.

Geometry is in the 729 px wide space of the picture the widget uses today,
so the drawing can replace it without touching the scale in Goldfish.qml.
Colours were sampled from the reference frames (see README.md).
"""
import sys

INK, BODY, LIGHT, LIMB, WHITE = "#0a0a0a", "#f47e26", "#f6bc8c", "#f49c52", "#ffffff"
STROKE = 7  # outline weight measured on the reference, in this space

# Silhouette, clockwise from the snout; the bottom is closed with a round
# belly because the reference hides it.
BODY_PTS = [(722, 260), (723, 317), (704, 371), (666, 414), (618, 443), (568, 462), (510, 478),
            (440, 490), (370, 494), (300, 492), (230, 482), (165, 460), (105, 420), (62, 370),
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


def front():
    s = 'stroke="%s" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round"' % (INK, STROKE)
    leg = '<path d="M%d 470v95a30 30 0 0 0 60 0v-95z" fill="%s" %s/>'
    return "\n".join([
        leg % (228, LIMB, s), leg % (452, LIMB, s),
        '<path d="M120 318C60 290 4 330 6 392c2 60 40 84 96 80 40-3 66-20 80-40z" fill="%s" %s/>' % (LIMB, s),
        '<path d="M14 372l52 6M22 424l50-10" fill="none" %s/>' % s,
        '<path d="%s" fill="%s" %s/>' % (smooth(BODY_PTS), BODY, s),
        '<path d="M112 146c-30 36-36 96-24 140 6 4 14 2 16-6 4-50 18-90 36-122 0-10-18-18-28-12z" fill="%s"/>' % LIGHT,
        '<ellipse cx="269.5" cy="184.5" rx="96" ry="90" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="495.5" cy="173" rx="90" ry="86.5" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="285" cy="188" r="45" fill="%s"/><circle cx="484" cy="177" r="45" fill="%s"/>' % (INK, INK),
        '<path d="M178 150l-20-8M172 172l-22 0M176 196l-20 10M584 128l20-10M590 150l22-2M590 174l20 6" fill="none" %s/>' % s,
        '<path d="M224 76c16-18 44-26 66-22M460 40c20-6 44 0 60 18" fill="none" %s stroke-opacity="1"/>' % s.replace('"7"', '"11"'),
        '<path d="M246 290c-8 36 14 62 46 60 18-1 30-10 36-22M448 304c8 26 34 36 58 26 22-9 30-34 20-56" fill="none" %s/>' % s,
        '<path d="M330 322c30 22 86 20 118-14" fill="none" %s/>' % s,
        '<circle cx="289" cy="308" r="30" fill="%s"/><circle cx="492" cy="298" r="30" fill="%s"/>' % (LIGHT, LIGHT),
    ])


if __name__ == "__main__":
    out = sys.argv[1]
    open(out + "/darwin-front.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -8 737 612" width="737" height="612">\n'
        '<title>Darwin, front view, neutral pose</title>\n%s\n</svg>\n' % front())
