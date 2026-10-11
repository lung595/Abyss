#!/usr/bin/env python3
"""Real-size evidence sheets of wake.html (NAK-271), captured from the page itself.

The page is rendered by WebKitGTK on a private broadway display, so nothing
appears on the live session. One sheet per theme: the 580 x 480 view at rest,
hovered, waking, woke up and with no answer (option A), then option B waking
and woke up, then Reduce motion, side by side at 1x, plus one capture of the
whole page. This WebKit has no GL and does not advance CSS transitions on a
steady clock, so they are switched off for the captures: each tile is the end
state of its step. A probe then clicks every switch and prints what changed. The page stays the thing judged; these are test
evidence only. Standard library, GTK 4, WebKitGTK 6.
"""
import json
import os
import subprocess
import sys
import time

OUT = os.path.dirname(os.path.abspath(__file__))
DISPLAY = ":91"
# Started before GTK loads: the backend is chosen, and its display opened, at import time.
os.environ.update(GDK_BACKEND="broadway", BROADWAY_DISPLAY=DISPLAY)
DAEMON = subprocess.Popen(["gtk4-broadwayd", DISPLAY], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1)

import cairo  # noqa: E402
import gi  # noqa: E402

gi.require_version("Gtk", "4.0")
gi.require_version("WebKit", "6.0")
from gi.repository import GLib, Gtk, WebKit  # noqa: E402

THEMES = {"dark": "", "light": "light", "wall": "wall"}
# State button to press, then the delay before the capture: the mock waits 3 s,
# so 1500 ms is mid-wait and 4600 ms is after the result has settled.
# Fourth and fifth fields: option class and Reduce motion class set by the page switches.
STATES = [("rest", "rest", 400, "optA", ""), ("hover", "hover", 400, "optA", ""),
          ("waking", "woke", 1500, "optA", ""), ("woke", "woke", 4600, "optA", ""),
          ("no-answer", "none", 4600, "optA", ""), ("b-waking", "woke", 1500, "optB", ""),
          ("b-woke", "woke", 4600, "optB", ""), ("rm-waking", "woke", 1500, "optA", "rm")]
SHOTS = [(t, s) for t in THEMES for s in STATES] + [(t, ("page", "rest", 400, "optA", "")) for t in THEMES]
# Returns the view rectangle in page coordinates and the boxes the layout rule is checked on.
SETUP = """if(!document.getElementById('snapfix')){var st=document.createElement('style');st.id='snapfix';
st.textContent='*{transition:none!important}';document.head.appendChild(st)}
var sw=function(g,v){document.querySelector('.seg[data-g='+g+'] button[data-v="'+v+'"]').click()};
sw('theme','%s');sw('opt','%s');sw('rm','%s');sw('lang','');
document.querySelector('[data-s=%s]').click();"""
# Proof that the four switches are wired: each click must change the page.
PROBE = """var r={};try{measure();r.measure='ok'}catch(e){r.measure=String(e)}
var sw=function(g,v){document.querySelector('.seg[data-g='+g+'] button[data-v="'+v+'"]').click()};
sw('opt','optB');r.afterB=document.body.className;sw('rm','rm');r.afterRm=document.body.className;
sw('theme','light');r.afterLight=document.body.className;
sw('lang','fr');r.fr=document.querySelector('[data-fr]').textContent;
sw('lang','');r.en=document.querySelector('[data-fr]').textContent;
r.rows=document.querySelectorAll('#ctr tr').length;r.bad=document.querySelectorAll('#ctr .bad').length;
r.table=[].map.call(document.querySelectorAll('#ctr tr'),function(t){return t.textContent});
JSON.stringify(r)"""
BOXES = """var q=function(s){var r=document.querySelector(s).getBoundingClientRect();return [r.left+scrollX,r.top+scrollY,r.width,r.height]};
JSON.stringify({scene:q('#scene'),body:q('#c1 .body'),lvl:q('#c1 .lvl'),ring:q('#c1 .ring'),nm:q('#c1 .nm'),floor:q('.floor'),hero:q('.card .hero'),pill:q('.pill'),kind:q('.card .kind')})"""


def capture(app, view, shots, got):
    theme, (name, button, settle, opt, rm) = shots[0]

    def settled():
        view.evaluate_javascript(BOXES, -1, None, None, None, snap)
        return False

    def snap(v, res):
        boxes = json.loads(v.evaluate_javascript_finish(res).to_string())
        view.get_snapshot(WebKit.SnapshotRegion.FULL_DOCUMENT, WebKit.SnapshotOptions.NONE, None, done, boxes)
        return False

    def done(v, res, boxes):
        got[(theme, name)] = (v.get_snapshot_finish(res), boxes)
        if shots[1:]:
            GLib.timeout_add(100, capture, app, view, shots[1:], got)
        else:
            view.evaluate_javascript(PROBE, -1, None, None, None, probed)

    def probed(v, res):
        got["probe"] = json.loads(v.evaluate_javascript_finish(res).to_string())
        app.quit()

    view.evaluate_javascript(SETUP % (THEMES[theme], opt, rm, button), -1, None, None, None,
                             lambda v, res: GLib.timeout_add(settle, settled))
    return False


def surface_of(texture):
    tmp = os.path.join(OUT, ".snap.png")
    texture.save_to_png(tmp)
    s = cairo.ImageSurface.create_from_png(tmp)
    os.remove(tmp)
    return s


def sheet(theme, got):
    """The view states in one row, cropped from the page at 1x."""
    out = cairo.ImageSurface(cairo.FORMAT_RGB24, 580 * len(STATES), 480)
    ctx = cairo.Context(out)
    for i, (name, *_) in enumerate(STATES):
        tex, boxes = got[(theme, name)]
        x, y = boxes["scene"][:2]
        ctx.set_source_surface(surface_of(tex), i * 580 - round(x), -round(y))
        ctx.rectangle(i * 580, 0, 580, 480)
        ctx.fill()
    out.write_to_png(os.path.join(OUT, "evidence-view-%s.png" % theme))
    surface_of(got[(theme, "page")][0]).write_to_png(os.path.join(OUT, "evidence-page-%s.png" % theme))


def main():
    got = {}
    try:
        app = Gtk.Application()

        def activate(a):
            win = Gtk.ApplicationWindow(application=a)
            win.set_default_size(1300, 900)
            view = WebKit.WebView()
            win.set_child(view)
            view.load_uri("file://" + os.path.join(OUT, "wake.html"))
            win.present()
            GLib.timeout_add(1000, capture, a, view, SHOTS, got)

        app.connect("activate", activate)
        app.run(None)
    finally:
        DAEMON.terminate()
    for theme in THEMES:
        sheet(theme, got)
    for name, *_ in STATES:
        print(name, json.dumps(got[("dark", name)][1]))
    print("probe", json.dumps(got["probe"], ensure_ascii=False, indent=1))


if __name__ == "__main__":
    sys.exit(main())
