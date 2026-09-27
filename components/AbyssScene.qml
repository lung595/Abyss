import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Common
import qs.Services
import qs.Widgets
import "Mesh.js" as Mesh
import "Layout.js" as Lay
import "Groups.js" as Groups
import "MyGroups.js" as MyGroups
import "Query.js" as Query
import "Spring.js" as Spring
import "Swim.js" as Swim
import "Grips.js" as Grips

// The deep, shared by the popout, the Control Center and the desktop.
//
// You are the jellyfish at the top; each peer is a creature on the sonar ring
// of its latency, linked to you by a ribbon of light whose width and waves
// are its live traffic. Never more than a few things are shown (Groups.js):
// the rest gather in shoals, and a search fogs what it leaves out.
// The deep is dark; the pointer carries a soft lamp and a magnetic lens that
// magnifies what it aims at, things swinging aside on springs. Resting on a
// shoal opens it by itself as a bubble over the blurred deep (GroupPeek).
// One clock (a 30 Hz Timer, 60 Hz while something follows the hand) moves
// the waves, the marine snow, the bob, the lens and the springs; it only runs
// while the scene is watched and something moves. Everything else is painted
// once and only redrawn on change.
Item {
    id: root

    property var source: null
    // Copy, SSH and browser helpers (the daemon); null in previews
    property var actions: null
    // The view is on screen (popout shown, Control Center open, desktop)
    property bool active: true
    property real cornerRadius: 16
    // Desktop: stay still until the pointer is over it
    property bool freezeWhenIdle: false
    property bool interacting: true
    // Control Center: a smaller top bar
    property bool compact: false
    // Desktop: the deep lives in a fishbowl drawn around it (FishBowl), so
    // it has no frame, water, reef or floor of its own; the top bar only
    // shows while the pointer is over it
    property bool borderless: false
    // In the desktop bowl: how far in from each side the surface (top bar,
    // sun) and the floor (caves, sleepers) must stay, as the glass narrows
    property real insetTop: 0
    property real insetFloor: 0
    readonly property bool chromeShown: !borderless || interacting || netsOpen || query !== ""

    readonly property Prefs prefs: Prefs {}
    readonly property var view: source ? source.view : Mesh.parse("", null, null, 0)
    readonly property bool connected: view.state === "connected"
    readonly property bool reduceMotion: prefs.reduceMotion
    readonly property bool awake: active && (!freezeWhenIdle || interacting || prefs.desktopLive)
    // The flow pauses while a bubble is open: the deep behind it is a still,
    // blurred picture
    readonly property bool flowing: awake && connected && !reduceMotion && prefs.pulses && peekId === ""

    // --- Colours: all from the theme; the deep stays dark in light mode, the
    // way Orbit keeps its night sky
    function mix(a, b, k) {
        return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1);
    }
    readonly property color _night: "#02040b"
    readonly property color _white: "#ffffff"
    readonly property color _grey: "#8a8fa0"
    // The abyss is dark from the surface down: no sunlight, only living light
    readonly property color abyss: mix(Theme.primary, _night, 0.94)
    readonly property color shallow: mix(Theme.primary, _night, 0.86)
    readonly property color ink: mix(Theme.primary, _white, 0.88)
    readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.62)
    readonly property color sleepColor: mix(Theme.primary, _grey, 0.7)
    readonly property color sunColor: mix(Theme.warning, _white, 0.4)
    readonly property color groupColor: mix(Theme.primary, Theme.tertiary, 0.35)
    readonly property var tints: [Theme.primary, Theme.tertiary, Theme.success, Theme.secondary, mix(Theme.primary, Theme.tertiary, 0.5), mix(Theme.tertiary, Theme.success, 0.5), mix(Theme.primary, Theme.success, 0.5), mix(Theme.secondary, Theme.tertiary, 0.5)]
    // Stable colour per peer name
    function tintOf(name) {
        let h = 0;
        const s = String(name || "");
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) >>> 0;
        return tints[h % tints.length];
    }

    // --- What is shown: at most maxItems things (Groups.js) ------------------
    readonly property real topH: 54
    readonly property var peerById: {
        const m = {};
        view.peers.forEach(p => m[p.id] = p);
        return m;
    }
    readonly property var downRelays: view.relays.filter(r => !r.available).map(r => r.name)
    readonly property var shown: view.peers.filter(p => p.online || prefs.showOffline)
    readonly property var filters: Query.parse(query, view.relays.map(r => r.name))
    readonly property int maxItems: Math.max(3, Math.min(10, prefs.maxItems))
    // Last arrangement; also the memory that keeps groups steady between reads
    property var arr: ({
            "items": [],
            "key": "",
            "stars": [],
            "solo": [],
            "hits": 0
        })

    function regroup() {
        _regroupLater = false;
        _lastSet = _setKey;
        arr = Groups.view(shown, maxItems, filters, {
            "favorites": prefs.favorites,
            "mine": prefs.groups,
            "broken": downRelays,
            "memo": arr
        });
    }
    // Groups follow the calm traffic (Mesh.follow), and never change under
    // your hand: while the pointer is on the deep, a bubble or card is open
    // or something is held, a traffic change waits. A peer coming or going
    // regroups at once.
    readonly property bool _handsOn: lensOn || peekId !== "" || cardId !== "" || _springing || _carrying
    // A group of mine made, changed or undone: at once
    readonly property var _mine: prefs.groups
    on_MineChanged: regroup()
    readonly property string _setKey: shown.map(p => p.id + (p.online ? "+" : "-")).join("|")
    property string _lastSet: ""
    property bool _regroupLater: false
    onShownChanged: {
        if (_handsOn && _setKey === _lastSet)
            _regroupLater = true;
        else
            regroup();
    }
    on_HandsOnChanged: {
        if (!_handsOn && _regroupLater)
            regroup();
    }
    onFiltersChanged: regroup()
    onMaxItemsChanged: regroup()

    function isBroken(p) {
        return !!p && p.online && p.relayed && downRelays.indexOf(p.relay) >= 0;
    }
    readonly property var itemById: {
        const m = {};
        arr.items.forEach(it => m[it.id] = it);
        return m;
    }
    // The item a peer is shown in (itself, or its group)
    function itemOfPeer(peerId) {
        const it = arr.items.find(i => i.type === "peer" ? i.peerId === peerId : i.members.indexOf(peerId) >= 0);
        return it ? it.id : "";
    }
    function trafficOf(it) {
        if (!it)
            return {
                "down": 0,
                "up": 0
            };
        const ps = it.type === "peer" ? [peerById[it.peerId]] : it.fog ? [] : it.members.map(id => peerById[id]);
        return ps.reduce((a, p) => p && p.online ? {
                "down": a.down + p.down,
                "up": a.up + p.up
            } : a, {
            "down": 0,
            "up": 0
        });
    }
    function tintOfItem(it) {
        return it.type === "peer" && peerById[it.peerId] ? tintOf(peerById[it.peerId].name) : groupColor;
    }
    // Each item as the layout sees a peer: placed by its steady latency (a
    // jitter never moves it); a group floats at the median depth of its
    // members, behind a relay only if all of them share it
    function _asPeer(it) {
        if (it.type === "peer") {
            const p = peerById[it.peerId];
            return Object.assign({}, p, {
                "id": it.id,
                "latencyMs": p.steadyMs !== undefined ? p.steadyMs : p.latencyMs
            });
        }
        const ms = it.members.map(id => peerById[id]).filter(p => p && p.online);
        const lat = ms.map(p => p.steadyMs !== undefined ? p.steadyMs : p.latencyMs).sort((a, b) => a - b);
        const via = ms.length && ms.every(p => p.relayed && p.relay === ms[0].relay) ? ms[0].relay : "";
        return {
            "id": it.id,
            "online": !it.asleep && !it.fog && ms.length > 0,
            "latencyMs": lat.length ? lat[lat.length >> 1] : 0,
            "relayed": via !== "",
            "relay": via
        };
    }
    readonly property var layItems: arr.items.filter(it => it.type !== "peer" || !!peerById[it.peerId]).map(_asPeer)
    readonly property var lay: Lay.layout(layItems, Math.max(240, width), Math.max(220, height), topH, {
        "top": insetTop,
        "floor": insetFloor,
        "caves": reefCaves
    }, _laid.deg)
    // The last layout's angles, so the next one keeps things on their side
    // (Layout._keepOrder). A constant object filled in place: reading it in
    // the binding above adds no dependency, so no binding loop
    readonly property var _laid: ({
            "deg": null
        })
    readonly property var frame: lay.frame
    // Delegates are rebuilt only when the set of items changes, not on
    // every traffic read
    readonly property string _peerKey: layItems.filter(p => p.id.startsWith("p:")).map(p => p.id).join("|")
    readonly property var peerItemIds: _peerKey ? _peerKey.split("|") : []
    readonly property string _groupKey: layItems.filter(p => p.id.startsWith("g:")).map(p => p.id).join("|")
    readonly property var groupItemIds: _groupKey ? _groupKey.split("|") : []
    readonly property string _relaysKey: Object.keys(lay.relays).sort().join("|")
    readonly property var relayNames: _relaysKey ? _relaysKey.split("|") : []

    function spotOf(id) {
        const p = lay.peers[id];
        return p ? Qt.point(p.x, p.y) : Qt.point(width / 2, frame.floorY);
    }
    function spotOfPeer(peerId) {
        return spotOf(itemOfPeer(peerId));
    }
    // Where it is drawn right now: its place plus the lens, a grab or a
    // swim under way (the sun and its beam follow a peer being dragged)
    // Where a peer really is, without the lens: its place, its swim and a
    // grab, but not the fisheye that shifts it at every pointer move (the
    // light hangs on this, so it holds still while you look around)
    function anchorOfPeer(peerId) {
        poseRev;
        const id = itemOfPeer(peerId), p = spotOf(id), n = _nudges[id], w = _tripPose[id];
        return Qt.point(p.x + (n ? n.x : 0) + (w ? w.dx : 0), p.y + (n ? n.y : 0) + (w ? w.dy : 0));
    }
    function drawnOfPeer(peerId) {
        const id = itemOfPeer(peerId), p = spotOf(id), o = offsetOf(id);
        return Qt.point(p.x + o.x, p.y + o.y);
    }

    // --- Awake and asleep --------------------------------------------------
    // power eases after the jellyfish is switched (0 asleep .. 1 awake). The
    // light spreads from the jellyfish outward when it wakes and draws back
    // into it when it sleeps: the farthest things wake last and sleep first.
    property real power: connected ? 1 : 0
    // The deep's swimming phase: it runs while someone watches, slower asleep
    // (breathing, bobbing, a shoal turning), and simply stops otherwise
    property real swim: 0
    readonly property bool floating: awake && !reduceMotion && peekId === ""
    // Inside a group only its members live: the deep behind is a still picture
    readonly property bool peekLive: awake && !reduceMotion && peekId !== ""
    function wakeAt(x, y) {
        const j = frame.jelly, d = Math.min(1, Math.hypot(x - j.x, y - j.y) / Math.max(200, height * 0.9));
        return Math.max(0, Math.min(1, power * 1.8 - d * 0.8));
    }
    function wakeOf(id) {
        const s = spotOf(id), o = offsetOf(id);
        return wakeAt(s.x + o.x, s.y + o.y);
    }
    // 0..1: how bright a peer shines (traffic), dimmed as it falls asleep
    function glowOf(p, wake) {
        if (!p || !p.online)
            return 0.04;
        return 0.04 + (0.11 + 0.85 * Mesh.level(p.down + p.up)) * (wake === undefined ? power : wake);
    }
    // The tentacle holding this item, once it has reached it (look: color,
    // width, level, warn, dashed), or null
    function gripOf(id) {
        if (ext < 0.98)
            return null;
        return tents.find(tn => tn.id === id) || null;
    }
    // Rim slots of the jellyfish held by a tentacle (the free ones hang loose)
    property var legsTaken: []
    // The cave under the pointer (-1: none): its thread shows only then
    property int caveHover: -1

    // --- The magnetic lens (Layout.js: lensFocus, lensCentre, lensed) -------
    // It follows the pointer, gently pulled toward nearby things (a soft
    // magnet: no jump), and focuses the thing nearest the pointer in the real
    // water, so a small move is enough to aim and aiming never gets harder.
    // What it magnifies and pushes aside swings there on a spring (Spring.js:
    // LENS), and back when it leaves. The wheel sets its strength (not in the
    // small Control Center view). Inside a bubble it works on the members.
    property string focusId: ""
    // The focused thing, only while the pointer is actually on it: the lens
    // aims from afar (it is a magnifier), but a click acts on what is under
    // the hand, never on something a hand-width away
    property string aimedId: ""
    readonly property real touchR: 60
    function _within(id, at) {
        let q;
        if (id.indexOf("m:") === 0) {
            q = groupPeek.memberPose(id.slice(2));
        } else {
            const h = spotOf(id), o = offsetOf(id);
            q = Qt.point(h.x + o.x, h.y + o.y);
        }
        return Math.hypot(q.x - at.x, q.y - at.y) <= touchR;
    }
    property bool lensOn: false
    property real lensX: 0
    property real lensY: 0
    property real lensK: compact ? 1 : 1.6
    property bool _lensMoving: false
    readonly property real lensR: Math.max(110, Math.min(170, width * 0.27))
    // Inside the bubble the lens shrinks to fit it
    readonly property real lensReach: peekId !== "" ? Math.min(lensR, peekR * 0.8) : lensR

    // Creature size at rest: small, so the lens has room to matter (a
    // busier peer is a little bigger)
    function creatureScale(p, wake) {
        return 0.6 + 0.24 * glowOf(p, wake);
    }
    // The peer whose creature is flying to or sitting on the open card
    readonly property string heroPeerId: cardHero.visible ? cardHero.peerId : ""
    // How visible a peer's creature is in the water: hidden while its twin is
    // on the card, fading back in as ‹ › steps away from it
    function heroOpacity(id) {
        if (id === heroPeerId)
            return 0;
        return id === cardHero.prevId ? cardHero.swap : 1;
    }

    // Where the things the lens can aim at rest, keyed like the springs:
    // the items of the deep by their Groups.js id, or, while a bubble is
    // open, its members by "m:" + peer id
    function _homes() {
        const m = {};
        if (peekId !== "") {
            peekMembers.forEach((id, i) => {
                const q = peekSpots[i];
                if (q)
                    m["m:" + id] = {
                        "x": peekCentre.x + q.x,
                        "y": peekCentre.y + q.y
                    };
            });
        } else {
            arr.items.forEach(it => {
                if (!it.fog && lay.peers[it.id])
                    m[it.id] = lay.peers[it.id];
            });
        }
        return m;
    }

    // Previews and scripts can hold the lens at a point (no real pointer)
    property point pinnedPointer: Qt.point(-1, -1)
    // Returns true when something moved (the tentacles must follow)
    function _lensStep(dt) {
        const pinned = pinnedPointer.x >= 0;
        const here = (pointer.hovered || pinned) && connected;
        // Nobody aiming and nothing swinging: nothing to do (the flow ticks)
        if (!here && !lensOn && focusId === "" && !Object.keys(_poses).length)
            return false;
        const homes = _homes();
        let gliding = false;
        if (here) {
            const at = pinned ? pinnedPointer : pointer.point.position;
            focusId = Lay.lensFocus(homes, at.x, at.y, lensReach * 0.9, focusId);
            aimedId = focusId !== "" && _within(focusId, at) ? focusId : "";
            const c = Lay.lensCentre(homes, at.x, at.y, lensReach * 0.45);
            if (!lensOn || reduceMotion) {
                lensX = c.x;
                lensY = c.y;
                lensOn = true;
            } else {
                // Time-based smoothing (~50 ms): same feel at any tick rate
                const a = 1 - Math.exp(-dt / 0.05);
                lensX += (c.x - lensX) * a;
                lensY += (c.y - lensY) * a;
            }
            gliding = Math.hypot(c.x - lensX, c.y - lensY) > 0.3;
            if (!gliding) {
                lensX = c.x;
                lensY = c.y;
            }
            _peekWatch(at);
        } else {
            lensOn = false;
            focusId = "";
            aimedId = "";
            dwell.stop();
            // While the light is carried, dragOver alone says when it leaves
            if (peekId !== "" && cardId === "" && pinnedPointer.x < 0 && !_carrying)
                peekLeave.start();
        }
        const swinging = _stepPoses(homes, dt);
        _lensMoving = gliding || swinging;
        return gliding || swinging;
    }

    // Lens springs: id -> {x, y, s, vx, vy, vs}, the offset and scale the
    // lens gives a thing; dropped once back at rest
    property var _poses: ({})
    function _stepPoses(homes, dt) {
        let moving = false, touched = false;
        Object.keys(homes).concat(Object.keys(_poses).filter(id => !homes[id])).forEach(id => {
            const h = homes[id];
            const l = h && lensOn ? Lay.lensed(h.x, h.y, lensX, lensY, lensReach, lensK) : null;
            const tx = l ? l.x - h.x : 0, ty = l ? l.y - h.y : 0, ts = l ? l.s : 1;
            let q = _poses[id];
            if (!q) {
                if (ts === 1)
                    return;
                q = _poses[id] = {
                    "x": 0,
                    "y": 0,
                    "s": 1,
                    "vx": 0,
                    "vy": 0,
                    "vs": 0
                };
            }
            touched = true;
            if (reduceMotion) {
                q.x = tx;
                q.y = ty;
                q.s = ts;
                q.vx = q.vy = q.vs = 0;
            } else {
                Spring.stepPose(q, tx, ty, ts, Spring.LENS, dt);
            }
            if (!Spring.poseSettled(q, tx, ty, ts))
                moving = true;
            else if (ts === 1)
                delete _poses[id];
        });
        if (touched)
            poseRev++;
        return moving;
    }

    // --- Grab and let go (GrabArea, Spring.js) -------------------------------
    // Any creature, shoal or bubble member can be dragged; let go, it swims
    // back home. id -> {x, y, vx, vy, tx, ty, held}: offset from its place
    property var _nudges: ({})
    // Bumped each tick so bindings re-read the lens springs and the nudges
    property int poseRev: 0
    property bool _springing: false
    // x, y: offset from its place · s: lens scale · b: body pulse (1 = at
    // rest) · f: facing (+1 right, -1 left, through 0 while turning) · a: tilt (deg)
    readonly property var _still: ({
            "x": 0,
            "y": 0,
            "s": 1,
            "b": 1,
            "f": 1,
            "a": 0
        })
    function nudgeOf(id) {
        poseRev;
        return _nudges[id] || _still;
    }
    // How a thing is drawn relative to its place: lens spring plus grab
    function offsetOf(id) {
        poseRev;
        const q = _poses[id], n = _nudges[id], w = _tripPose[id];
        const face = _faces[id] || 1;
        if (!q && !n && !w)
            return face === 1 ? _still : Object.assign({}, _still, {
                "f": face
            });
        return {
            "x": (q ? q.x : 0) + (n ? n.x : 0) + (w ? w.dx : 0),
            "y": (q ? q.y : 0) + (n ? n.y : 0) + (w ? w.dy : 0),
            "s": q ? q.s : 1,
            "b": w ? w.b : 1,
            "f": w ? w.f : face,
            "a": w ? w.a : 0
        };
    }

    // --- Swimming to a new place (Swim.js) ----------------------------------
    // When the layout moves a thing (its latency changed, a regroup), it
    // swims there in its animal's gait instead of jumping: the trip is an
    // offset from its new place, so its tentacle follows it all the way.
    // id -> trip · id -> where the trip is now (x, y, and dx, dy from its
    // new place: offsetOf never reads the layout, no binding loop) · id -> facing at rest
    property var _trips: ({})
    property var _tripPose: ({})
    property var _faces: ({})
    // Where each thing stood in the previous layout
    property var _lastSpots: ({})
    // A resized view jumps into place: only the water itself moving swims
    property string _lastSize: ""
    property bool _swimming: false
    function _kindOf(id) {
        const it = arr.items.find(x => x.id === id), p = it && it.type === "peer" ? peerById[it.peerId] : null;
        return p ? p.kind : "shoal";
    }
    function _planTrips() {
        const size = Math.round(width) + "x" + Math.round(height);
        const next = {}, now = awake && !reduceMotion && size === _lastSize, before = Object.keys(_trips).length;
        let planned = false;
        _lastSize = size;
        Object.keys(lay.peers).forEach(id => {
            const q = lay.peers[id], was = _lastSpots[id];
            next[id] = [q.x, q.y];
            if (!now) {
                delete _trips[id];
                delete _tripPose[id];
                return;
            }
            if (!was || Math.hypot(was[0] - q.x, was[1] - q.y) < 2)
                return;
            // Leave from where it is drawn now (a trip may be under way)
            const cur = _tripPose[id], from = cur ? [cur.x, cur.y] : was;
            // Neighbours bend their paths different ways
            const side = id.length % 2 ? 1 : -1;
            _trips[id] = Swim.plan(from, [q.x, q.y], _kindOf(id), t, side, _faces[id] || 1);
            _tripPose[id] = _tripAt(_trips[id]);
            planned = true;
        });
        _lastSpots = next;
        _swimming = Object.keys(_trips).length > 0;
        // Only when something changed: a layout read inside a binding must
        // not ripple back into it
        if (planned || before !== Object.keys(_trips).length)
            poseRev++;
    }
    // Falling asleep mid-trip (the desktop once the pointer leaves) must not
    // freeze things half-way, stacked where they left: they land at once
    function _landTrips() {
        Object.keys(_trips).forEach(id => {
            const w = _tripAt(_trips[id]);
            _faces[id] = w.f;
        });
        _trips = {};
        _tripPose = {};
        _swimming = false;
        poseRev++;
    }
    onAwakeChanged: {
        if (awake)
            return;
        const moved = _swimming || Object.keys(_poses).length > 0;
        if (_swimming)
            _landTrips();
        // Same for the lens's pull: back to rest, not frozen mid-swing
        if (Object.keys(_poses).length) {
            _poses = {};
            lensOn = false;
            _lensMoving = false;
            poseRev++;
        }
        // No tick follows once asleep: the tentacles must be rebuilt here,
        // or they stay drawn where things were a moment ago
        if (moved)
            _build();
    }
    function _tripAt(trip) {
        const w = Swim.at(trip, t);
        w.dx = w.x - trip.to[0];
        w.dy = w.y - trip.to[1];
        return w;
    }
    function _tripStep() {
        const ids = Object.keys(_trips);
        if (!ids.length)
            return false;
        ids.forEach(id => {
            const w = lay.peers[id] ? _tripAt(_trips[id]) : null;
            if (!w || w.done) {
                if (w)
                    _faces[id] = w.f;
                delete _trips[id];
                delete _tripPose[id];
            } else
                _tripPose[id] = w;
        });
        _swimming = Object.keys(_trips).length > 0;
        poseRev++;
        return true;
    }
    function grab(id, dx, dy) {
        const n = _nudges[id] || {
            "x": 0,
            "y": 0,
            "vx": 0,
            "vy": 0
        };
        n.tx = dx;
        n.ty = dy;
        n.held = true;
        _nudges[id] = n;
        _springing = true;
    }
    function letGo(id) {
        const n = _nudges[id];
        if (!n)
            return;
        n.held = false;
        n.tx = 0;
        n.ty = 0;
    }
    // Returns true when something moved (the tentacles must follow)
    function _nudgeStep(dt) {
        const ids = Object.keys(_nudges);
        if (!ids.length)
            return false;
        ids.forEach(id => {
            const n = _nudges[id];
            if (reduceMotion) {
                n.x = n.tx;
                n.y = n.ty;
                n.vx = n.vy = 0;
            } else {
                Spring.step(n, n.tx, n.ty, n.held ? Spring.HELD : Spring.HOME, dt);
            }
            if (!n.held && (reduceMotion || Spring.settled(n, 0, 0)))
                delete _nudges[id];
        });
        poseRev++;
        _springing = Object.keys(_nudges).length > 0;
        return true;
    }

    // --- The bubble (GroupPeek) ----------------------------------------------
    // Rest the pointer on a shoal and it opens by itself, a large lit bubble
    // over the blurred, dimmed deep, its members on rings with the busiest at
    // the top; a click opens it at once (prefs.groupOpen picks either or
    // both). Leaving it closes it; so do Esc and a click outside.
    property string peekId: ""
    // Members shown (peer ids, busiest first), fixed while open so they
    // never jump between two traffic reads
    property var peekMembers: []
    property point peekCentre: Qt.point(0, 0)
    property point peekFrom: Qt.point(0, 0)
    readonly property int peekMax: 24
    readonly property real peekR: Math.max(90, Math.min(170, (height - topH - 50) / 2, width * 0.36))
    readonly property var peekSpots: Lay.ringSpots(peekMembers.length, peekR)
    // The pointer rests near the shoal this long before it opens
    property string _dwellId: ""
    property point _dwellAt: Qt.point(0, 0)
    // Closed with Esc or a click outside: not again until the pointer leaves it
    property string _peekBlock: ""

    function openPeek(id) {
        const it = itemById[id];
        if (!it || it.type !== "group" || it.fog)
            return;
        const home = spotOf(id), o = offsetOf(id), R = peekR;
        peekFrom = Qt.point(home.x + o.x, home.y + o.y);
        // The camera brings the group to the middle of the deep (D133)
        peekCentre = Qt.point(width / 2, Math.max(topH + R + 34, Math.min(height - R - 12, topH + (height - topH) / 2)));
        peekMembers = it.members.map(m => peerById[m]).filter(p => !!p).sort((a, b) => (b.online - a.online) || (b.down + b.up) - (a.down + a.up)).slice(0, peekMax).map(p => p.id);
        _dwellId = "";
        dwell.stop();
        peekLeave.stop();
        _poolEntered = false;
        focusId = "";
        peekId = id;
        cardId = "";
        worldShot.scheduleUpdate();
        _lensMoving = true;
        forceActiveFocus();
    }
    function closePeek() {
        peekLeave.stop();
        if (peekId === "")
            return;
        _peekBlock = peekId;
        peekId = "";
        focusId = "";
        _build();
        // The deep shows again as it is now
        worldShot.scheduleUpdate();
        _lensMoving = true;
    }
    function _peekWatch(at) {
        // The carried light has its own rules (dragOver)
        if (_carrying)
            return;
        if (peekId !== "") {
            const out = Math.hypot(at.x - peekCentre.x, at.y - peekCentre.y) > peekR + 24;
            if (out && cardId === "") {
                if (!peekLeave.running)
                    peekLeave.start();
            } else {
                peekLeave.stop();
            }
            return;
        }
        const it = itemById[focusId];
        const near = !!it && it.type === "group" && !it.fog && aimedId === focusId;
        if (_peekBlock !== "" && (focusId !== _peekBlock || !near))
            _peekBlock = "";
        if (!near || prefs.groupOpen === "click" || focusId === _peekBlock || cardId !== "" || _springing) {
            dwell.stop();
            _dwellId = "";
            return;
        }
        // A new shoal, or the pointer still moving: wait again
        if (_dwellId !== focusId || Math.hypot(at.x - _dwellAt.x, at.y - _dwellAt.y) > 6) {
            _dwellId = focusId;
            _dwellAt = Qt.point(at.x, at.y);
            dwell.restart();
        }
    }
    Timer {
        id: dwell
        interval: 170
        onTriggered: {
            if (root._dwellId !== "" && root._dwellId === root.focusId)
                root.openPeek(root._dwellId);
        }
    }
    Timer {
        id: peekLeave
        interval: 220
        onTriggered: root.closePeek()
    }
    // The group vanished (a regroup, a search): close its bubble
    onItemByIdChanged: {
        if (peekId !== "" && !itemById[peekId]) {
            // Kept as a group of mine while open: the same bubble, new id
            if (_peekBecomes !== "" && itemById[_peekBecomes])
                peekId = _peekBecomes;
            else
                closePeek();
        }
        _peekBecomes = "";
    }
    property string _peekBecomes: ""

    // Where a peer's creature is drawn right now: in the bubble, on its own,
    // or inside its shoal (for the card's flight)
    function peerPose(peerId) {
        poseRev;
        if (peekId !== "" && peekMembers.indexOf(peerId) >= 0)
            return groupPeek.memberPose(peerId);
        const id = itemOfPeer(peerId), home = spotOf(id), o = offsetOf(id);
        const own = id.indexOf("p:") === 0;
        return {
            "x": home.x + o.x,
            "y": home.y + o.y,
            "s": o.s * (own ? creatureScale(peerById[peerId]) : 0.35)
        };
    }

    // --- Tentacles (kept while retracting after a disconnect) ---------------
    property var tents: []
    property var tentPts: ({})
    property var threads: []
    onLayChanged: {
        const deg = {};
        Object.keys(lay.peers).forEach(id => {
            if (lay.peers[id].deg !== undefined)
                deg[id] = lay.peers[id].deg;
        });
        _laid.deg = deg;
        _planTrips();
        _build();
    }
    onCaveHoverChanged: _build()
    onConnectedChanged: {
        if (!awake || reduceMotion) {
            ext = connected ? 1 : 0;
            power = ext;
        }
        _build();
    }

    function _build() {
        if (!connected) {
            threads = [];
            if (legsTaken.length)
                legsTaken = [];
            return;
        }
        const f = lay.frame, j = f.jelly, byId = {};
        // Built here: itemById may not have caught up with this layout yet
        arr.items.forEach(it => byId[it.id] = it);
        const live = layItems.filter(p => p.online && lay.peers[p.id] && byId[p.id]);
        const at = {};
        live.forEach(p => {
            const q = lay.peers[p.id], o = offsetOf(p.id);
            at[p.id] = [q.x + o.x, q.y + o.y];
        });
        live.sort((a, b) => Math.atan2(at[b.id][1] - j.y, at[b.id][0] - j.x) - Math.atan2(at[a.id][1] - j.y, at[a.id][0] - j.x));
        // Each tentacle takes over the loose thread under its direction (live
        // is sorted left to right); past Lay.LEGS they share the rim
        const slots = Lay.legSlots(j, live.map(p => at[p.id][0]));
        const taken = slots || Array.from({
            "length": Lay.LEGS
        }, (_, k) => k);
        if (taken.join() !== legsTaken.join())
            legsTaken = taken;
        const pts = {};
        tents = live.map((p, i) => {
            const it = byId[p.id], tr = trafficOf(it), via = p.relayed ? lay.relays[p.relay] : null;
            const start = slots ? Lay.legPoint(j, slots[i]) : Lay.rimPoint(j, i, live.length);
            const line = Lay.tentacle(start, at[p.id], via ? [via.x, via.y] : null);
            pts[p.id] = line;
            const lv = Mesh.level(tr.down + tr.up);
            return {
                "id": p.id,
                "pts": line,
                "len": Lay.length(line),
                "color": tintOfItem(it),
                "level": lv,
                "width": Lay.ribbonWidth(lv),
                "down": Mesh.level(tr.down),
                "up": Mesh.level(tr.up),
                "dashed": it.type === "peer" && prefs.isMuted(it.peerId),
                "warn": it.type === "peer" ? isBroken(peerById[it.peerId]) : it.members.some(id => isBroken(peerById[id]))
            };
        });
        tentPts = pts;
        const nets = source ? source.networks : [];
        const th = [];
        nets.forEach((n, i) => {
            const peer = view.peers.find(p => p.name === n.via);
            const id = peer ? itemOfPeer(peer.id) : "", at = lay.peers[id];
            // Only for the cave under the pointer: always shown, it crossed the whole deep
            if (!n.on || !at || !peer.online || caveHover !== i)
                return;
            const o = offsetOf(id);
            th.push({
                "pts": Lay.thread([Lay.caveX(f, i), f.floorY - Lay.CAVE_TOP], [at.x + o.x, at.y + o.y]),
                "color": Theme.tertiary
            });
        });
        threads = th;
    }

    // The lamp fades in when the pointer comes over the deep (or an open
    // group); the blur when a group opens (brief transitions)
    property real lampMix: lensOn ? 1 : 0
    // The disc the lamp lights, and the reef's colours (dark and lit copies)
    readonly property real lampR: lensR * 1.25
    readonly property color reefShadow: Qt.darker(abyss, 1.7)
    readonly property color reefStone: mix(Theme.secondary, abyss, 0.5)
    readonly property color reefSand: mix(Theme.secondary, ink, 0.45)
    // The water down by the floor (Water.qml darkens towards the bottom):
    // what far rock melts into, so it never shows lighter than the sea
    readonly property color reefWater: Qt.darker(abyss, 1.4)
    readonly property var reefTints: [Theme.tertiary, Theme.secondary, Theme.primary, Theme.success]
    readonly property int reefCaves: source ? source.networks.length : 0
    // Where the lens is across the deep (-1 left, 1 right): the reef's parallax
    readonly property real reefDrift: width > 0 ? Math.max(-1, Math.min(1, (lensX - width / 2) / (width / 2))) : 0
    Behavior on lampMix {
        NumberAnimation {
            duration: root.reduceMotion ? 0 : 300
        }
    }
    // The camera, from the whole deep (0) to the open group (1): it glides
    // and zooms towards the group as it opens, and back as it closes. Only
    // one still, blurred picture of the deep moves (a brief transition).
    property real camera: peekId !== "" ? 1 : 0
    Behavior on camera {
        NumberAnimation {
            duration: root.reduceMotion ? 0 : root.peekId !== "" ? 520 : 440
            easing.type: Easing.InOutCubic
        }
    }
    readonly property real blurMix: camera
    // How much closer the camera gets, and how far the picture slides
    // towards the middle (never so far that an edge of it shows)
    readonly property real camZoom: 1 + 0.5 * camera
    function _camShift(from, to, size) {
        const k = camZoom - 1;
        return Math.max(-k * (size - from), Math.min(k * from, (to - from) * camera));
    }

    // --- The clock ---------------------------------------------------------
    property real t: 0
    property real ext: connected ? 1 : 0
    property double _last: 0
    property var _pulses: []
    property var _acc: ({})
    property var _snow: []
    readonly property int poolSize: 90
    readonly property int snowSize: 18

    Timer {
        id: clock
        // 60 Hz while the lens or a grabbed item follows the hand, 30 Hz for the flow alone
        interval: root._lensMoving || root._springing || root._swimming ? 16 : 33
        repeat: true
        running: root.awake && (root.flowing || root.floating || root.peekLive || root._lensMoving || root._springing || root._swimming || Math.abs(root.ext - (root.connected ? 1 : 0)) > 0.001 || Math.abs(root.power - (root.connected ? 1 : 0)) > 0.001)
        onRunningChanged: {
            root._last = Date.now();
            if (!running)
                root._hideMovers();
        }
        onTriggered: root.step()
    }

    function _hideMovers() {
        _pulses = [];
        for (let i = 0; i < poolSize; i++) {
            const it = pulsePool.itemAt(i);
            if (it)
                it.visible = false;
        }
    }

    function step() {
        const now = Date.now();
        const dt = Math.min(0.1, Math.max(0, (now - _last) / 1000));
        _last = now;
        t += dt;
        const target = connected ? 1 : 0;
        if (ext !== target)
            ext = reduceMotion ? target : target > ext ? Math.min(1, ext + dt / 1.1) : Math.max(0, ext - dt / 0.7);
        // The light spreads out from the jellyfish (wakeAt), a little slower
        if (power !== target)
            power = reduceMotion ? target : target > power ? Math.min(1, power + dt / 1.8) : Math.max(0, power - dt / 1.3);
        // Floating: slower asleep, so the deep seems to sleep
        if (floating || peekLive)
            swim += dt * (0.35 + 0.65 * power);
        // Grabbed things first, then the lens; tentacles rebuilt once (not
        // while a bubble hides the deep)
        const swam = _tripStep();
        const moved = _nudgeStep(dt) || swam;
        if ((_lensStep(dt) || moved) && peekId === "")
            _build();
        // Waves of light: inward on the upper half = download (toward you),
        // outward on the lower half = upload; faster and longer when busy
        if (flowing && ext >= 1) {
            tents.forEach(tn => {
                if (tn.warn)
                    return;
                const a = _acc[tn.id] || (_acc[tn.id] = {
                        "i": 0,
                        "o": 0
                    });
                a.i += dt * (0.25 + 3.2 * tn.down);
                a.o += dt * (0.12 + 2 * tn.up);
                if (a.i > 1) {
                    a.i = 0;
                    _pulses.push({
                        "id": tn.id,
                        "f": 1,
                        "v": -1,
                        "len": tn.len,
                        "col": tn.color,
                        "lv": tn.down,
                        "w": tn.width
                    });
                }
                if (a.o > 1) {
                    a.o = 0;
                    _pulses.push({
                        "id": tn.id,
                        "f": 0,
                        "v": 1,
                        "len": tn.len,
                        "col": tn.color,
                        "lv": tn.up,
                        "w": tn.width
                    });
                }
            });
            _pulses = _pulses.filter(q => {
                q.f += q.v * dt * (70 + 260 * q.lv) / Math.max(40, q.len);
                return q.f >= 0 && q.f <= 1 && !!tentPts[q.id];
            }).slice(-poolSize);
        } else if (_pulses.length) {
            _pulses = [];
        }
        for (let i = 0; i < poolSize; i++) {
            const it = pulsePool.itemAt(i);
            if (!it)
                continue;
            const q = _pulses[i], pts = q ? tentPts[q.id] : null;
            if (!pts) {
                it.visible = false;
                continue;
            }
            const pt = Lay.pointAt(pts, q.f), deg = Lay.angleAt(pts, q.f), rad = deg * Math.PI / 180;
            // Sideways: upper half for what comes in, lower half for what goes out
            const side = (q.v < 0 ? -1 : 1) * Math.max(0, q.w / 4 - 0.5);
            it.x = pt[0] - Math.sin(rad) * side;
            it.y = pt[1] + Math.cos(rad) * side;
            it.rotation = deg;
            it.len = 10 + 20 * q.lv;
            it.thick = Math.max(2, q.w + 0.6);
            it.inward = q.v < 0;
            it.tint = q.col;
            // Fade in and out at both ends of the tentacle
            it.opacity = Math.min(1, q.f * 8, (1 - q.f) * 8);
            it.visible = true;
        }
        // Marine snow drifting down
        if (flowing) {
            if (_snow.length !== snowSize)
                _snow = Array.from({
                    "length": snowSize
                }, (_, i) => ({
                            "x": Math.random() * width,
                            "y": Math.random() * height,
                            "v": 5 + Math.random() * 9
                        }));
            for (let i = 0; i < snowSize; i++) {
                const s = _snow[i], it = snowPool.itemAt(i);
                s.y += s.v * dt;
                if (s.y > frame.floorY) {
                    s.y = frame.surfaceY;
                    s.x = Math.random() * width;
                }
                if (it) {
                    it.x = s.x;
                    it.y = s.y;
                }
            }
        }
    }

    // --- Watching: the source only reads NetBird while someone looks --------
    property bool _watching: false
    function _watch() {
        const want = active && !!source;
        if (want !== _watching && source) {
            source.watch(want);
            _watching = want;
        }
    }
    onActiveChanged: _watch()
    onSourceChanged: _watch()
    Component.onCompleted: _watch()
    Component.onDestruction: {
        if (_watching && source)
            source.watch(false);
    }

    // --- Actions -----------------------------------------------------------
    property string cardId: ""
    // 0 -> 1 as the card opens: the desktop bowl darkens its water and
    // fades its glass with it, so the card reads clearly (a short fade only)
    property real cardMix: cardId !== "" ? 1 : 0
    Behavior on cardMix {
        NumberAnimation {
            duration: root.reduceMotion ? 0 : 400
        }
    }
    property bool netsOpen: false
    property string dropName: ""
    // The carried light is over the middle of the open group: dropping it
    // there gives Internet to the whole group (GroupPeek shows what it will do)
    property bool aimAll: false
    property string query: ""
    property string omenHidden: ""

    // The open card, as in Orbit: it rises from the bottom while the water
    // dims, and the peer's creature flies onto its top edge (CardHero)
    readonly property real cardW: Math.min(360, width - 24)
    readonly property real medallion: Math.round(Math.min(104, cardW * 0.3))
    // Always this tall, whoever it shows (the details scroll inside)
    readonly property real cardH: Math.min(400, height - medallion * 0.4 - 16)
    property bool _cardWasOpen: false
    onCardIdChanged: {
        if (cardId !== "")
            cardHero.peerId = cardId;
        // A still of the deep for the card's glass, taken once as it opens
        if (cardId !== "" && !_cardWasOpen)
            cardShot.scheduleUpdate();
        _cardWasOpen = cardId !== "";
    }
    // The peers ‹ › steps through, in the order of the deep
    readonly property var cardOrder: shown.map(p => p.id)
    function stepCard(dir) {
        const n = cardOrder.length;
        const i = cardOrder.indexOf(cardId);
        if (cardId === "" || n < 2)
            return;
        const next = cardOrder[((i < 0 ? 0 : i) + dir + n) % n];
        cardHero.switchTo(next);
        cardId = next;
    }

    function openCard(id) {
        cardId = cardId === id ? "" : id;
        netsOpen = false;
        forceActiveFocus();
    }
    // A click on a thing: a peer (or a bubble member, "m:") opens its card,
    // a shoal opens its bubble (Enter always; a click unless groups open on
    // hover only), the fog (what a search left out) clears the
    // search
    function activate(id, byKey) {
        if (id.indexOf("m:") === 0) {
            openCard(id.slice(2));
            return;
        }
        const it = itemById[id];
        if (!it)
            return;
        if (it.type === "peer")
            openCard(it.peerId);
        else if (it.fog)
            query = "";
        else if (byKey || prefs.groupOpen !== "hover")
            openPeek(id);
        forceActiveFocus();
    }
    function copy(text, what) {
        if (actions)
            actions.copy(text);
        ToastService.showInfo(what + " copied", text);
    }
    function ssh(peer) {
        if (actions)
            actions.ssh(peer.fqdn || peer.ip, prefs.terminal);
    }
    function openWeb(peer) {
        if (actions)
            actions.openUrl("http://" + (peer.fqdn || peer.ip));
    }
    function _peerAt(px, py) {
        let best = null, dist = 46;
        arr.items.forEach(it => {
            const p = it.type === "peer" ? peerById[it.peerId] : null, s = lay.peers[it.id];
            if (!p || !p.online || !s)
                return;
            const d = Math.hypot(s.x - px, s.y - py);
            if (d < dist) {
                dist = d;
                best = p;
            }
        });
        return best;
    }
    // --- Internet, carried (SurfaceSun) -------------------------------------
    readonly property var exitPeer: source && source.exitNode ? view.peers.find(p => p.name === source.exitNode) || null : null
    // The group of mine the exit goes through, if any
    readonly property var exitMine: MyGroups.byId(prefs.groups, prefs.exitGroup)
    // What the carried light says under it
    property string dropHint: "Drop on a peer"
    function setExit(peerName, groupId) {
        if (actions && actions.setExit) {
            actions.setExit(peerName, groupId);
        } else if (source) {
            // No daemon (previews): the same choice, without the failover
            const g = MyGroups.byId(prefs.groups, groupId);
            const p = g ? MyGroups.pickExit(view.peers, g.members, source.exitNode) : null;
            prefs.set("exitGroup", g ? groupId : "");
            source.setExitNode(p ? p.name : peerName);
        }
    }
    // The nearest shoal around a point (for the carried light)
    function _groupAt(px, py) {
        let best = null, dist = 50;
        arr.items.forEach(it => {
            const s = lay.peers[it.id];
            if (it.type !== "group" || it.fog || !s)
                return;
            const d = Math.hypot(s.x - px, s.y - py);
            if (d < dist) {
                dist = d;
                best = it;
            }
        });
        return best;
    }
    // What the light would go to: { peer } or { group: id of mine, name }
    function _sunTarget(px, py) {
        if (peekId !== "") {
            let best = null, dist = 34;
            peekMembers.forEach(id => {
                const p = peerById[id], q = groupPeek.memberPose(id);
                const d = Math.hypot(q.x - px, q.y - py);
                if (p && p.online && d < dist) {
                    dist = d;
                    best = p;
                }
            });
            if (best)
                return { "peer": best };
            // The middle of any group: all of it (a shoal the mesh made is
            // kept as a group of yours, so its members stay put)
            const it = itemById[peekId];
            if (it && it.type === "group" && !it.fog && Math.hypot(px - peekCentre.x, py - peekCentre.y) < peekR)
                return it.mine ? { "group": it.mine, "name": it.label } : { "keep": it.id, "name": _keepName(it) };
            return null;
        }
        const p = _peerAt(px, py);
        if (p)
            return { "peer": p };
        const g = _groupAt(px, py);
        return g && g.mine ? { "group": g.mine, "name": g.label } : null;
    }
    property string _sunDwellId: ""
    // "5 busy" -> "Busy": the name a shoal keeps when it becomes yours
    function _keepName(it) {
        const s = it.label.replace(/^\d+\s+/, "");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }
    // The light is in hand: groups hold still until it is let go
    property bool _carrying: false
    // The bubble opens in the middle, away from the hand that carried the
    // light there: leaving it only counts once the light has been inside
    property bool _poolEntered: false
    function dragOver(px, py) {
        _carrying = true;
        const t = _sunTarget(px, py);
        dropName = t && t.peer ? t.peer.name : "";
        aimAll = peekId !== "" && !!t && !t.peer;
        if (peekId !== "")
            focusId = t && t.peer ? "m:" + t.peer.id : "";
        // Leaving the bubble closes it; resting on a shoal opens it
        const inPool = peekId !== "" && Math.hypot(px - peekCentre.x, py - peekCentre.y) <= peekR + 24;
        if (inPool)
            _poolEntered = true;
        if (peekId !== "") {
            if (inPool || !_poolEntered)
                peekLeave.stop();
            else if (!peekLeave.running)
                peekLeave.start();
        }
        const g = peekId === "" ? _groupAt(px, py) : null;
        if (!g || g.asleep || g.id === _peekBlock) {
            if (!g)
                _peekBlock = "";
            sunDwell.stop();
            _sunDwellId = "";
        } else if (_sunDwellId !== g.id) {
            _sunDwellId = g.id;
            sunDwell.restart();
        }
        const it = itemById[peekId];
        if (t)
            dropHint = "Internet through " + (t.peer ? t.peer.name : "all of " + t.name);
        else if (g && !g.asleep)
            dropHint = "Opening " + g.label + "…";
        else if (peekId !== "" && !inPool && _poolEntered)
            dropHint = "Leaving the group";
        else
            dropHint = it && it.mine ? "Drop on a peer, or here for all" : "Drop on a peer";
    }
    function dropSun(px, py) {
        const t = _sunTarget(px, py);
        const inPool = peekId !== "" && Math.hypot(px - peekCentre.x, py - peekCentre.y) <= peekR + 24;
        _carrying = false;
        dropName = "";
        aimAll = false;
        dropHint = "Drop on a peer";
        sunDwell.stop();
        _sunDwellId = "";
        if (peekId !== "")
            focusId = "";
        // Let go inside a bubble, on nothing: keep what was there
        if (!t && inPool)
            return;
        if (t && t.keep) {
            // What you see in the bubble is what you keep (all of it when
            // the bubble could only show part)
            const all = itemById[t.keep].members;
            const r = MyGroups.create(prefs.groups, peekId === t.keep && all.length <= peekMax ? peekMembers : all, t.name);
            if (peekId === t.keep)
                _peekBecomes = "g:u:" + r.id;
            // Saved first: the daemon looks the group up to pick its member
            prefs.set("groups", r.groups);
            setExit("", r.id);
            return;
        }
        setExit(t && t.peer ? t.peer.name : "", t && t.group ? t.group : "");
    }
    Timer {
        id: sunDwell
        interval: 450
        onTriggered: {
            if (root._sunDwellId !== "")
                root.openPeek(root._sunDwellId);
            root._sunDwellId = "";
        }
    }

    // --- Groups of mine: the right-click menu (MyGroups.js) ----------------
    // The thing the menu is for ("p:<id>", "m:<peer id>" or a group item id)
    property string menuId: ""
    property point menuAt: Qt.point(0, 0)
    // The group being named (just made, or "Rename")
    property string naming: ""
    function openMenu(id, at) {
        menuId = id;
        menuAt = at;
        naming = "";
        netsOpen = false;
        forceActiveFocus();
    }
    function closeMenu() {
        menuId = "";
        naming = "";
        forceActiveFocus();
    }
    // A click on you: the one step that moves the connection forward
    function pressJelly() {
        if (!source)
            return;
        if (view.state === "needsLogin")
            source.login();
        else if (view.state === "stopped")
            source.startService();
        else
            source.toggle();
    }
    function _menuPeer(id) {
        if (id.indexOf("m:") === 0)
            return peerById[id.slice(2)] || null;
        const it = itemById[id];
        return it && it.type === "peer" ? peerById[it.peerId] || null : null;
    }
    // [{ text, act, arg }] for the thing under the menu
    function menuActions(id, mine) {
        const out = [], p = _menuPeer(id), it = itemById[id];
        if (id === "me") {
            // You: what the top bar holds, for the bowl that has none
            if (!source)
                return out;
            out.push({ "text": connected || view.state === "connecting" ? "Disconnect" : view.state === "needsLogin" ? "Sign in" : "Connect", "act": "toggle" });
            const ps = source.profiles;
            if (ps.length > 1)
                out.push({ "text": "Profile: " + ps[(ps.indexOf(source.profile) + 1) % ps.length], "act": "profile" });
            out.push({ "text": prefs.showOffline ? "Hide offline peers" : "Show offline peers", "act": "offline" });
        } else if (p) {
            const g = MyGroups.groupOf(mine, p.id);
            mine.filter(x => x !== g).forEach(x => out.push({ "text": "Add to " + x.name, "act": "join", "arg": x.id }));
            out.push({ "text": "New group", "act": "create", "arg": p.id });
            if (g)
                out.push({ "text": "Leave " + g.name, "act": "leave", "arg": p.id });
        } else if (it && it.mine) {
            out.push({ "text": prefs.exitGroup === it.mine ? "Stop Internet through it" : "Internet through it", "act": "exit", "arg": it.mine });
            out.push({ "text": "Rename", "act": "rename", "arg": it.mine });
            out.push({ "text": "Ungroup", "act": "remove", "arg": it.mine });
        } else if (it && it.type === "group" && !it.fog) {
            out.push({ "text": "Keep as my group", "act": "keep", "arg": id });
        }
        return out;
    }
    function doMenu(a) {
        const mine = prefs.groups;
        if (a.act === "create" || a.act === "keep") {
            const ids = a.act === "create" ? [a.arg] : itemById[a.arg].members;
            const r = MyGroups.create(mine, ids);
            prefs.set("groups", r.groups);
            // Named at once, or left as "Group n" by clicking away
            naming = r.id;
            return;
        }
        if (a.act === "rename") {
            naming = a.arg;
            return;
        }
        if (a.act === "toggle")
            pressJelly();
        else if (a.act === "profile") {
            const ps = source.profiles;
            source.setProfile(ps[(ps.indexOf(source.profile) + 1) % ps.length]);
        } else if (a.act === "offline")
            prefs.set("showOffline", !prefs.showOffline);
        else if (a.act === "join")
            prefs.set("groups", MyGroups.join(mine, a.arg, _menuPeer(menuId).id));
        else if (a.act === "leave")
            prefs.set("groups", MyGroups.leave(mine, a.arg));
        else if (a.act === "remove") {
            // Internet stays with the peer it was going through
            if (prefs.exitGroup === a.arg)
                setExit(source ? source.exitNode : "", "");
            prefs.set("groups", MyGroups.remove(mine, a.arg));
        } else if (a.act === "exit")
            setExit("", prefs.exitGroup === a.arg ? "" : a.arg);
        closeMenu();
    }
    function nameGroup(id, name) {
        prefs.set("groups", MyGroups.rename(prefs.groups, id, name));
        closeMenu();
    }

    // --- Layers ------------------------------------------------------------
    layer.enabled: false
    // In the fishbowl the water is wider than the scene: glows spill over
    clip: !borderless

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.borderless ? 0 : root.cornerRadius
        color: root.borderless ? "transparent" : root.abyss
        clip: !root.borderless

        // Everything that lives in the water; behind an open bubble it is
        // replaced by one blurred picture of itself (worldShot)
        Item {
            id: world
            anchors.fill: parent
            enabled: root.peekId === ""

            Water {
                anchors.fill: parent
                scene: root
                frame: root.frame
                shallow: root.shallow
                abyss: root.abyss
                ink: root.ink
                open: root.borderless
            }
            Reef {
                anchors.fill: parent
                visible: !root.borderless
                frame: root.frame
                ink: root.ink
                shadow: root.reefShadow
                stone: root.reefStone
                sand: root.reefSand
                water: root.reefWater
                tints: root.reefTints
                caves: root.reefCaves
                t: root.t
                live: root.flowing
                drift: root.reefDrift
            }
            // The lamp reveals the reef: the lit copy, seen only in a soft
            // disc around the lens. Only that disc is redrawn as it moves.
            Reef {
                id: litReef
                anchors.fill: parent
                visible: !root.borderless
                lit: true
                frame: root.frame
                ink: root.ink
                shadow: root.reefShadow
                stone: root.reefStone
                sand: root.reefSand
                water: root.reefWater
                tints: root.reefTints
                caves: root.reefCaves
                t: root.t
                // Only moves while the lamp shows it
                live: root.flowing && root.lampMix > 0.01
                drift: root.reefDrift
            }
            ShaderEffectSource {
                id: litSpot
                width: root.lampR * 2
                height: root.lampR * 2
                visible: false
                sourceItem: litReef
                hideSource: true
                live: root.lampMix > 0.01 && !root.borderless
                sourceRect: Qt.rect(root.lensX - root.lampR, root.lensY - root.lampR, root.lampR * 2, root.lampR * 2)
            }
            // The disc's soft edge (a scene-graph shape: unlike a Canvas, it
            // renders into its layer while hidden)
            Shape {
                id: lampMask
                width: root.lampR * 2
                height: root.lampR * 2
                visible: false
                layer.enabled: true
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: root.lampR
                        centerY: root.lampR
                        centerRadius: root.lampR
                        focalX: root.lampR
                        focalY: root.lampR
                        GradientStop {
                            position: 0.62
                            color: "white"
                        }
                        GradientStop {
                            position: 1
                            color: "transparent"
                        }
                    }
                    PathRectangle {
                        width: root.lampR * 2
                        height: root.lampR * 2
                    }
                }
            }
            MultiEffect {
                x: root.lensX - root.lampR
                y: root.lensY - root.lampR
                width: root.lampR * 2
                height: root.lampR * 2
                opacity: root.lampMix
                visible: opacity > 0.01 && !root.borderless
                source: litSpot
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: lampMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            // A click opens what the lens focuses, when the pointer is on it
            MouseArea {
                anchors.fill: parent
                cursorShape: root.aimedId !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    root.netsOpen = false;
                    if (root.aimedId !== "" && root.cardId === "")
                        root.activate(root.aimedId);
                    else
                        root.cardId = "";
                    root.forceActiveFocus();
                }
            }

            // Marine snow
            Repeater {
                id: snowPool
                model: root.snowSize
                Rectangle {
                    visible: root.flowing
                    width: 1.6
                    height: 1.6
                    radius: 0.8
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.35)
                    x: -10
                }
            }

            // The pointer's lamp: what it shows is the lit reef above; this
            // is only a faint glow in the water around it (painted once,
            // only moved; a brief fade in and out)
            Halo {
                readonly property real reach: root.lensR * 1.4
                visible: opacity > 0.01
                opacity: root.lampMix
                width: reach * 2
                height: reach * 2
                x: root.lensX - reach
                y: root.lensY - reach
                color: root.mix(root.ink, Theme.primary, 0.3)
                strength: 0.06
            }

            // Internet exit: a soft beam from the surface onto the exit peer
            LightShaft {
                readonly property var exitPeer: root.source && root.source.exitNode ? root.view.peers.find(p => p.name === root.source.exitNode) : null
                readonly property point at: exitPeer ? root.drawnOfPeer(exitPeer.id) : Qt.point(0, 0)
                visible: !!exitPeer && exitPeer.online && root.connected && height > 20
                // From the light, which hangs still above the peer's place
                fromX: root.anchorOfPeer(exitPeer ? exitPeer.id : "").x
                fromY: root.frame.surfaceY
                toX: at.x
                toY: at.y
                color: root.sunColor
            }

            Repeater {
                model: root.source ? root.source.networks : []
                Cave {
                    required property var modelData
                    required property int index
                    scene: root
                    net: modelData
                    x: Lay.caveX(root.frame, index)
                    y: root.frame.floorY + 8
                    onHoveredChanged: {
                        if (hovered)
                            root.caveHover = index;
                        else if (root.caveHover === index)
                            root.caveHover = -1;
                    }
                    onToggled: {
                        if (root.source && root.connected)
                            root.source.toggleNetwork(modelData.id);
                    }
                }
            }

            Tentacles {
                id: tentacles
                anchors.fill: parent
                scene: root
                tents: root.tents
                threads: root.threads
                ext: root.ext
            }

            // Waves of light running along the ribbons (moved by the clock)
            Repeater {
                id: pulsePool
                model: root.poolSize
                Item {
                    property bool inward: true
                    property color tint: "white"
                    property real len: 20
                    property real thick: 3
                    visible: false
                    Rectangle {
                        width: parent.len
                        height: parent.thick
                        radius: height / 2
                        x: -width / 2
                        y: -height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 0.5
                                color: parent.parent.inward ? Qt.lighter(parent.parent.tint, 1.6) : Qt.rgba(1, 1, 1, 0.85)
                            }
                            GradientStop {
                                position: 1
                                color: "transparent"
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.relayNames
                Lantern {
                    required property string modelData
                    scene: root
                    name: modelData
                    down: root.downRelays.indexOf(modelData) >= 0
                    tint: root.mix(Theme.primary, Theme.tertiary, 0.5)
                    x: root.lay.relays[modelData] ? root.lay.relays[modelData].x : 0
                    y: root.lay.relays[modelData] ? root.lay.relays[modelData].y : 0
                }
            }

            Repeater {
                model: root.groupItemIds
                School {
                    required property string modelData
                    required property int index
                    readonly property var it: root.itemById[modelData]
                    visible: !!it
                    scene: root
                    item: it || ({
                            "id": modelData,
                            "label": "",
                            "members": []
                        })
                    spot: root.spotOf(modelData)
                    tint: root.groupColor
                    phase: index * 1.9
                }
            }

            Repeater {
                model: root.peerItemIds
                Creature {
                    required property string modelData
                    required property int index
                    readonly property var it: root.itemById[modelData]
                    readonly property var p: it ? root.peerById[it.peerId] : null
                    visible: !!p
                    scene: root
                    itemId: modelData
                    peer: p || ({
                            "id": modelData,
                            "name": "",
                            "kind": "desktop",
                            "online": false,
                            "down": 0,
                            "up": 0
                        })
                    spot: root.spotOf(modelData)
                    onFloor: !!root.lay.peers[modelData] && root.lay.peers[modelData].floor
                    tint: root.tintOf(peer.name)
                    isTop: root.connected && root.view.topId === peer.id
                    favorite: root.prefs.isFavorite(peer.id)
                    muted: root.prefs.isMuted(peer.id)
                    highlighted: root.cardId === peer.id || (root.dropName !== "" && root.dropName === peer.name)
                    phase: index * 1.37
                }
            }

            Jellyfish {
                id: jelly
                scene: root
                x: root.frame.jelly.x
                y: root.frame.jelly.y
                r: root.frame.jelly.r
                lit: Math.max(0.08, root.ext)
                phase: root.swim
                taken: root.legsTaken
            }
            // "you", beside the bell (the search sits on the other side)
            Chip {
                x: root.frame.jelly.x - root.frame.jelly.r * 1.25 - width
                y: root.frame.jelly.y - height / 2
                title: jellyArea.containsMouse ? root.view.me.name + " · you" : "you"
                sub: jellyArea.containsMouse ? root.view.me.ip : ""
                ink: root.connected ? root.abyss : root.ink
                subInk: root.connected ? Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.7) : root.inkDim
                color: root.connected ? Theme.tertiary : Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.7)
            }
            MouseArea {
                id: jellyArea
                hoverEnabled: true
                x: root.frame.jelly.x - root.frame.jelly.r
                y: root.frame.jelly.y - root.frame.jelly.r * 1.6
                width: root.frame.jelly.r * 2
                height: root.frame.jelly.r * 2.6
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.openMenu("me", mapToItem(root, mouse.x, mouse.y));
                        return;
                    }
                    root.pressJelly();
                }
            }

            // When not connected: what is going on, and the one action that helps
            Column {
                visible: !root.connected
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.frame.bandTop + (root.frame.bandBottom - root.frame.bandTop) * 0.3
                spacing: 10
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ({
                            "connecting": "Reaching the mesh…",
                            "needsLogin": "NetBird needs you to sign in",
                            "stopped": "NetBird is not running"
                        })[root.view.state] || "The deep is asleep"
                    wrapMode: Text.NoWrap
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.ink
                }
                ActionChip {
                    visible: root.view.state !== "connecting" && !!root.source
                    anchors.horizontalCenter: parent.horizontalCenter
                    primary: true
                    icon: ({
                            "needsLogin": "login",
                            "stopped": "play_arrow"
                        })[root.view.state] || "power_settings_new"
                    text: ({
                            "needsLogin": "Sign in",
                            "stopped": "Start NetBird"
                        })[root.view.state] || "Connect"
                    onClicked: {
                        if (root.view.state === "needsLogin")
                            root.source.login();
                        else if (root.view.state === "stopped")
                            root.source.startService();
                        else
                            root.source.connect();
                    }
                }
            }
        }

        HoverHandler {
            id: pointer
            onPointChanged: root._lensMoving = true
            onHoveredChanged: root._lensMoving = true
        }
        WheelHandler {
            enabled: !root.compact
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                root.lensK = Math.max(0.6, Math.min(3, root.lensK + (event.angleDelta.y > 0 ? 0.2 : -0.2)));
                root._lensMoving = true;
            }
        }

        // The deep behind an open bubble: one still picture of it, taken as
        // the bubble opens (and as it closes), blurred and dimmed. Nothing
        // behind re-renders or re-blurs while the bubble is open.
        ShaderEffectSource {
            id: worldShot
            anchors.fill: parent
            sourceItem: world
            live: false
            // Only a source for the blurred copy below, never shown itself:
            // in the fishbowl nothing opaque would cover it
            hideSource: root.blurMix > 0
            visible: false
        }
        // The deep behind the open card, for its glass: one still picture
        // taken as the card opens and blurred once; the card cuts its shape
        // out of it (PeerCard)
        ShaderEffectSource {
            id: cardShot
            anchors.fill: parent
            sourceItem: world
            live: false
            visible: false
        }
        MultiEffect {
            id: cardGlass
            anchors.fill: parent
            visible: false
            layer.enabled: root.cardId !== "" || peerCard.visible
            source: cardShot
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 48
            blur: 1
            brightness: -0.12
        }
        // In the fishbowl the scene has no frame, so the zoomed copy's edges
        // would show as a box: it melts away towards them instead (an oval
        // mask, only there)
        Item {
            id: camMask
            anchors.fill: parent
            visible: false
            layer.enabled: root.borderless
            // A round glow, squashed to the scene's shape (a scene-graph
            // shape: unlike a Canvas, it renders into its layer while hidden)
            Shape {
                width: parent.width
                height: parent.width
                transform: Scale {
                    yScale: camMask.width > 0 ? camMask.height / camMask.width : 1
                }
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: camMask.width / 2
                        centerY: camMask.width / 2
                        centerRadius: camMask.width / 2
                        focalX: camMask.width / 2
                        focalY: camMask.width / 2
                        GradientStop {
                            position: 0.72
                            color: "white"
                        }
                        GradientStop {
                            position: 1
                            color: "transparent"
                        }
                    }
                    PathRectangle {
                        width: camMask.width
                        height: camMask.width
                    }
                }
            }
        }
        // The ring where the water bends round an open group's pool: clear
        // inside and outside, full on the pool's edge (see the bent copy)
        Item {
            id: poolRing
            anchors.fill: parent
            visible: false
            layer.enabled: root.blurMix > 0
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: groupPeek.cx
                        centerY: groupPeek.cy
                        centerRadius: groupPeek.homeR * 1.4
                        focalX: groupPeek.cx
                        focalY: groupPeek.cy
                        GradientStop {
                            position: 0.5
                            color: "transparent"
                        }
                        GradientStop {
                            position: 0.72
                            color: "white"
                        }
                        GradientStop {
                            position: 1
                            color: "transparent"
                        }
                    }
                    PathRectangle {
                        width: poolRing.width
                        height: poolRing.height
                    }
                }
            }
        }
        // The zoomed copy is larger than the scene: keep it inside, even in
        // the fishbowl where the scene itself does not clip
        Item {
            anchors.fill: parent
            clip: true
            visible: root.blurMix > 0
            layer.enabled: root.borderless && visible
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: camMask
                // With a spread of 1, a threshold of 0.5 follows the mask's alpha
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
            MultiEffect {
                anchors.fill: parent
                source: worldShot
                transform: [
                    Scale {
                        origin.x: root.peekFrom.x
                        origin.y: root.peekFrom.y
                        xScale: root.camZoom
                        yScale: root.camZoom
                    },
                    Translate {
                        x: root._camShift(root.peekFrom.x, root.peekCentre.x, root.width)
                        y: root._camShift(root.peekFrom.y, root.peekCentre.y, root.height)
                    }
                ]
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 32
                blur: 0.85 * root.blurMix
                brightness: -0.675 * root.blurMix
                saturation: -0.5 * root.blurMix
            }
            // Round the pool the water bends like a lens: the same picture,
            // a little magnified about the pool and less blurred, seen
            // through a soft ring, no line drawn. Only while a group is open
            Item {
                anchors.fill: parent
                visible: root.blurMix > 0
                opacity: root.blurMix
                layer.enabled: visible
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: poolRing
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                MultiEffect {
                    anchors.fill: parent
                    source: worldShot
                    transform: [
                        Scale {
                            origin.x: root.peekFrom.x
                            origin.y: root.peekFrom.y
                            xScale: root.camZoom
                            yScale: root.camZoom
                        },
                        Translate {
                            x: root._camShift(root.peekFrom.x, root.peekCentre.x, root.width)
                            y: root._camShift(root.peekFrom.y, root.peekCentre.y, root.height)
                        },
                        Scale {
                            origin.x: groupPeek.cx
                            origin.y: groupPeek.cy
                            xScale: 1.12
                            yScale: 1.12
                        }
                    ]
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blurMax: 32
                    blur: 0.4 * root.blurMix
                    brightness: -0.375 * root.blurMix
                    saturation: -0.3 * root.blurMix
                }
            }
            // Outside the open group's pool the deep falls away into the dark:
            // clear round the pool, near black at the edges (a gradient over
            // one rectangle, cheap to move with the camera)
            Shape {
                anchors.fill: parent
                opacity: root.blurMix
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: groupPeek.cx
                        centerY: groupPeek.cy
                        centerRadius: Math.max(groupPeek.homeR + 1, Math.hypot(root.width, root.height) * 0.75)
                        focalX: groupPeek.cx
                        focalY: groupPeek.cy
                        focalRadius: groupPeek.homeR
                        GradientStop {
                            position: 0
                            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.38)
                        }
                        GradientStop {
                            position: 0.18
                            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.97)
                        }
                        GradientStop {
                            position: 1
                            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.98)
                        }
                    }
                    PathRectangle {
                        width: root.width
                        height: root.height
                    }
                }
            }
        }
        // A click outside the bubble closes it
        MouseArea {
            anchors.fill: parent
            visible: root.peekId !== ""
            z: 19
            onClicked: root.closePeek()
        }
        GroupPeek {
            id: groupPeek
            z: 20
            scene: root
            open: root.peekId !== ""
            item: root.itemById[root.peekId] || null
            members: root.peekMembers
            spots: root.peekSpots
            centre: root.peekCentre
            from: root.peekFrom
            radius: root.peekR
        }
        // Internet, as the light at the surface. It rides above the bubble:
        // carried over a group, the group opens, and the light can be left on
        // one of its members, or in the middle of a group of mine for all of it
        SurfaceSun {
            visible: root.connected && !!root.source && (dragging || root.cardId === "" && (root.peekId === "" || groupPeek.lit))
            z: 22
            scene: root
            // In the open group it carries: in the middle, tied to its members
            home: groupPeek.lit ? Qt.point(groupPeek.cx, groupPeek.cy) : root.exitPeer ? Qt.point(root.anchorOfPeer(root.exitPeer.id).x, root.frame.surfaceY) : Qt.point(root.width - root.insetTop - 58, root.frame.surfaceY)
            label: groupPeek.lit ? "" : root.exitMine && root.exitPeer ? "Internet via " + root.exitMine.name + " · " + root.exitPeer.name : root.exitPeer ? "Internet via " + root.exitPeer.name : "Internet"
            onDropped: (px, py) => root.dropSun(px, py)
        }
        // The open group's name (click to rename) and its settings, at the top
        GroupTitle {
            z: 21
            scene: root
            item: groupPeek._shown || null
            sub: groupPeek.summary
            reveal: root.blurMix
            visible: reveal > 0.01
            x: (root.width - width) / 2
            y: root.topH + 6
        }

        // The desktop bowl has none: its totals are scratched into the glass
        TopBar {
            id: bar
            opacity: root.chromeShown && !root.borderless ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation {
                    duration: root.reduceMotion ? 0 : 200
                }
            }
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.leftMargin: 8 + root.insetTop
            anchors.rightMargin: 8 + root.insetTop
            scene: root
            view: root.view
            source: root.source
            compact: root.compact
            onNetworksClicked: {
                root.netsOpen = !root.netsOpen;
                root.cardId = "";
            }
        }

        // Networks and the Internet exit, from the bar
        Rectangle {
            visible: root.netsOpen && !!root.source
            anchors.top: bar.bottom
            anchors.topMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 8
            width: 250
            height: netCol.implicitHeight + 16
            radius: 12
            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.92)
            border.width: 1
            border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)
            z: 30
            Column {
                id: netCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                StyledText {
                    text: "NETWORKS"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: root.inkDim
                }
                Repeater {
                    model: root.source ? root.source.networks : []
                    Item {
                        required property var modelData
                        width: netCol.width
                        height: 32
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                text: modelData.id
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: root.ink
                            }
                            StyledText {
                                text: modelData.cidr + " · via " + modelData.via
                                font.pixelSize: 10
                                font.family: Theme.monoFontFamily
                                color: root.inkDim
                            }
                        }
                        ActionChip {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            text: modelData.on ? "On" : "Off"
                            checked: modelData.on
                            accent: Theme.tertiary
                            ink: root.ink
                            onClicked: root.source.toggleNetwork(modelData.id)
                        }
                    }
                }
                Item {
                    visible: !!root.source && root.source.exitNode !== ""
                    width: netCol.width
                    height: 32
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        StyledText {
                            text: "Internet exit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: root.ink
                        }
                        StyledText {
                            text: "0.0.0.0/0 · via " + (root.exitMine ? root.exitMine.name + " · " : "") + (root.source ? root.source.exitNode : "")
                            font.pixelSize: 10
                            font.family: Theme.monoFontFamily
                            color: root.inkDim
                        }
                    }
                    ActionChip {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "Stop"
                        ink: root.ink
                        onClicked: root.setExit("", "")
                    }
                }
                StyledText {
                    width: netCol.width
                    text: "Tip: drag the light at the surface onto a peer, or a group of yours (right-click a creature), to send your Internet through it."
                    font.pixelSize: 10
                    color: root.inkDim
                }
            }
        }

        // Groups of mine: the right-click menu. A click anywhere else closes it.
        MouseArea {
            anchors.fill: parent
            visible: root.menuId !== ""
            z: 39
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.closeMenu()
        }
        Rectangle {
            id: menu
            readonly property var acts: root.menuId !== "" ? root.menuActions(root.menuId, root.prefs.groups) : []
            readonly property var named: MyGroups.byId(root.prefs.groups, root.naming)
            visible: root.menuId !== "" && (acts.length > 0 || !!named)
            z: 40
            width: 200
            height: menuCol.implicitHeight + 12
            // Opens at the pointer, kept inside the view
            x: Math.max(6, Math.min(root.width - width - 6, root.menuAt.x + 4))
            y: Math.max(6, Math.min(root.height - height - 6, root.menuAt.y + 4))
            radius: 12
            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.94)
            border.width: 1
            border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)

            Column {
                id: menuCol
                x: 6
                y: 6
                width: parent.width - 12
                spacing: 2
                // Naming a group: type, Enter keeps it, Esc or a click away leaves it as is
                Rectangle {
                    visible: !!menu.named
                    width: parent.width
                    height: 32
                    radius: 8
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08)
                    TextInput {
                        id: nameField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.ink
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.primaryText
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        maximumLength: 32
                        selectByMouse: true
                        onAccepted: root.nameGroup(root.naming, text)
                        Keys.onEscapePressed: root.closeMenu()
                    }
                    Connections {
                        target: root
                        function onNamingChanged() {
                            if (!menu.named)
                                return;
                            nameField.text = menu.named.name;
                            nameField.selectAll();
                            nameField.forceActiveFocus();
                        }
                    }
                }
                StyledText {
                    visible: !!menu.named
                    leftPadding: 10
                    text: "Enter to keep the name"
                    font.pixelSize: 10
                    color: root.inkDim
                }
                Repeater {
                    model: menu.named ? [] : menu.acts
                    Rectangle {
                        required property var modelData
                        width: menuCol.width
                        height: 30
                        radius: 8
                        color: rowArea.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.1) : "transparent"
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 10
                            width: parent.width - 20
                            elide: Text.ElideRight
                            text: modelData.text
                            font.pixelSize: 12
                            color: root.ink
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.doMenu(modelData)
                        }
                    }
                }
            }
        }

        // A warning (relay down, management unreachable, silent peer)
        Rectangle {
            readonly property var omen: root.view.omens.length ? root.view.omens[0] : null
            readonly property string key: omen ? omen.text : ""
            visible: !!omen && root.omenHidden !== key && root.cardId === ""
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 24, omenText.implicitWidth + 58)
            height: 30
            radius: 15
            color: Theme.warning
            z: 25
            StyledText {
                id: omenText
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: hide.left
                anchors.verticalCenter: parent.verticalCenter
                text: "⚠ " + (parent.omen ? parent.omen.text : "")
                wrapMode: Text.NoWrap
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.abyss
            }
            MouseArea {
                id: hide
                anchors.right: parent.right
                width: 34
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: root.omenHidden = parent.key
                StyledText {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.abyss
                }
            }
        }

        // What the search understood, beside the bell (across from "you")
        Chip {
            visible: root.query !== ""
            x: Math.min(root.width - width - 8, root.frame.jelly.x + root.frame.jelly.r * 1.25)
            y: root.frame.jelly.y - height / 2
            z: 26
            title: "⌕ " + root.query + "  ·  " + (root.arr.hits || "no") + " match" + (root.arr.hits === 1 ? "" : "es")
            sub: root.filters.map(f => f.label).join("  ·  ")
            third: root.arr.hits === 1 ? "Enter: open · Esc: clear" : "Esc: clear"
            ink: root.arr.hits ? root.sunColor : Theme.warning
        }

        // Dims the water behind the open card; a click there closes it. In
        // the bowl it stays clear: the bowl darkens its own water (cardMix)
        Rectangle {
            anchors.fill: parent
            z: 39
            color: root.borderless ? "transparent" : "black"
            opacity: root.cardId !== "" ? 0.4 : 0
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation {
                    duration: root.reduceMotion ? 0 : 400
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.cardId = ""
            }
        }

        PeerCard {
            id: peerCard
            // The last opened peer, kept while the card slides away
            readonly property var p: root.peerById[cardHero.peerId] || null
            readonly property real openY: root.height - height - 8
            visible: !!p && opacity > 0.01
            width: root.cardW
            height: root.cardH
            x: (root.width - width) / 2
            y: root.cardId !== "" ? openY : root.height + 20
            opacity: root.cardId !== "" ? 1 : 0
            Behavior on y {
                NumberAnimation {
                    duration: root.reduceMotion ? 0 : 480
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: root.reduceMotion ? 0 : 300
                }
            }
            topPad: root.medallion * 0.6 + 4
            z: 40
            scene: root
            source: root.source
            peer: p || ({
                    "id": "",
                    "name": "",
                    "kind": "desktop",
                    "online": false,
                    "down": 0,
                    "up": 0,
                    "rx": 0,
                    "tx": 0,
                    "ip": "",
                    "fqdn": ""
                })
            tint: root.tintOf(peer.name)
            history: root.source && p && root.source.history[p.id] ? root.source.history[p.id] : []
            isTop: !!p && root.view.topId === p.id
            isExit: !!p && !!root.source && root.source.exitNode === p.name
            favorite: !!p && root.prefs.isFavorite(p.id)
            muted: !!p && root.prefs.isMuted(p.id)
            viaNetworks: root.source && p ? root.source.networks.filter(n => n.via === p.name) : []
            onClosed: root.cardId = ""
            glass: cardGlass
            clearWater: root.borderless
            glassAt: Qt.point(x, y)
            prevPeer: cardHero.prevPeer
            prevFavorite: !!prevPeer && root.prefs.isFavorite(prevPeer.id)
            prevIsTop: !!prevPeer && root.view.topId === prevPeer.id
            swap: cardHero.swap
            canStep: root.cardOrder.length > 1
            onStep: dir => root.stepCard(dir)
        }

        // The creature flies from its place in the water onto the card's top edge
        CardHero {
            id: cardHero
            // Only while it is out of the water (open, or swimming back home):
            // nothing to follow otherwise
            readonly property var home: open || visible ? root.peerPose(peerId) : ({
                    "x": 0,
                    "y": 0,
                    "s": 1
                })
            z: 41
            scene: root
            open: root.cardId !== ""
            // From where its creature is drawn: alone, in its shoal or in the bubble
            from: Qt.point(home.x, home.y)
            fromScale: home.s
            // As in Orbit, it aims at the card's current top edge, not where the
            // card will land: it dives toward the rising card and rides up with
            // it. On close it lets the card sink and swims straight home.
            to: Qt.point(root.width / 2, (open ? peerCard.y : peerCard.openY) + root.medallion * 0.1)
            diameter: root.medallion
        }
    }

    // --- Keyboard: type anywhere to search ---------------------------------
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (menuId !== "")
                closeMenu();
            else if (query !== "")
                query = "";
            else if (cardId !== "" || netsOpen) {
                cardId = "";
                netsOpen = false;
            } else if (peekId !== "")
                closePeek();
            else
                return;
            event.accepted = true;
            return;
        }
        if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && cardId !== "") {
            stepCard(event.key === Qt.Key_Left ? -1 : 1);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const hits = arr.items.filter(i => !i.fog);
            if (query !== "" && arr.hits === 1 && hits.length === 1)
                activate(hits[0].id, true);
            else if (focusId !== "")
                activate(focusId, true);
            else
                return;
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Backspace && query !== "")
            query = query.slice(0, -1);
        else if (event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && /^[\w .<>\-àâäéèêëîïôöùûüç]$/i.test(event.text) && (query !== "" || event.text !== " "))
            query += event.text.toLowerCase();
        else
            return;
        event.accepted = true;
    }
}
