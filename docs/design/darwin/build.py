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
        # The fin is the body colour on the reference and reaches 8 px further
        # left than the first tracing, hence the shift and the wider viewBox.
        '<g transform="translate(-8 0)"><path d="M120 330C95 312 60 310 38 318C20 326 9 345 8 368c-2 4-2 8 0 12c0 30 10 60 32 80c18 14 45 18 70 12l60-17z" fill="%s" %s/>' % (BODY, s),
        '<path d="M10 352l38 6M9 386l42-2M20 426l38-12" fill="none" %s/></g>' % s,
        '<path d="%s" fill="%s" %s/>' % (smooth(BODY_PTS), BODY, s),
        '<path d="M112 146c-30 36-36 96-24 140 6 4 14 2 16-6 4-50 18-90 36-122 0-10-18-18-28-12z" fill="%s"/>' % LIGHT,
        '<ellipse cx="269.5" cy="184.5" rx="96" ry="90" fill="%s" %s/>' % (WHITE, s),
        '<ellipse cx="495.5" cy="173" rx="90" ry="86.5" fill="%s" %s/>' % (WHITE, s),
        '<circle cx="285" cy="188" r="47" fill="%s"/><circle cx="484" cy="177" r="47" fill="%s"/>' % (INK, INK),
        '<path d="M178 150l-20-8M172 172l-22 0M176 196l-20 10M584 128l20-10M590 150l22-2M590 174l20 6" fill="none" %s/>' % s,
        '<path d="M224 76c16-18 44-26 66-22M460 40c20-6 44 0 60 18" fill="none" %s stroke-opacity="1"/>' % s.replace('"7"', '"18"'),
        cheek(286, 314, 63, 203, 118, 1), cheek(503, 301, 59, -30, 62, 0),
        '<path d="M346 320Q398 352 448 306" fill="none" %s/>' % s,
        '<circle cx="290" cy="307" r="30" fill="%s"/><circle cx="492" cy="297" r="30" fill="%s"/>' % (LIGHT, LIGHT),
    ])


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


def swim():
    s = 'stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"' % INK
    return "\n".join([
        # Leg kicked up behind the body.
        '<path d="M520 125C535 70 570 35 620 28c35-3 50 27 30 50-20 17-50 17-65 62" fill="%s" %s/>' % (BODY, s),
        # Darker band where the leg leaves the body, as on the reference.
        '<path d="M524 112l34 22 10-20-36-20z" fill="%s"/>' % BAND,
        '<path d="%s" fill="%s" %s/>' % (smooth(SWIM_PTS), BODY, s),
        '<path d="M158 222c-14 20-12 52 4 70 8 4 14-2 12-10-8-18-8-36 0-52-2-8-10-12-16-8z" fill="%s"/>' % LIGHT,
        # Tail fin under the arm, then the arm reaching forward; both open
        # paths so the joint with the body carries no outline.
        '<path d="M150 352c-28 30-10 80 30 92 36 10 66-6 70-36" fill="%s" %s/>' % (BODY, s),
        '<path d="M158 392l22 12M170 408l22 12M184 422l22 12" fill="none" %s/>' % s,
        '<path d="M218 318C160 288 92 288 50 320c-35 25-30 65 0 70 35 2 60-25 100-40L200 372" fill="%s" %s/>' % (BODY, s),
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
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 -8 745 612" width="745" height="612">\n'
        '<title>Darwin, front view, neutral pose</title>\n%s\n</svg>\n' % front())
    open(out + "/darwin-swim.svg", "w").write(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 480" width="680" height="480">\n'
        '<title>Darwin, side view, swimming</title>\n%s\n</svg>\n' % swim())
