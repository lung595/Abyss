.pragma library

// The queue of the Send station: jobs (one file for one device), their states
// and the session history. Pure: every function takes a state and returns a new
// one, so the view only binds to it and gjs tests every transition
// (tests/sendQueue.test.js). Nothing here touches disk: the history is the
// session's memory and dies with the window (privacy, value 5).

// Caps keep a runaway drop or a long session from growing without bound
const MAX_JOBS = 200;
const MAX_HISTORY = 50;

const QUEUED = "queued";
const SENDING = "sending";
const DONE = "done";
const FAILED = "failed";
const CANCELLED = "cancelled";

function empty() {
    return { "jobs": [], "history": [], "nextId": 1 };
}

// Files x devices, in drop order, up to MAX_JOBS live jobs. Duplicates of a
// live job (same file, same device) are skipped: a double drop sends once.
function add(state, paths, devices) {
    const jobs = state.jobs.slice();
    let id = state.nextId;
    let skipped = 0;
    for (const device of devices) {
        for (const path of paths) {
            const dup = jobs.some(j => j.device === device && j.path === path);
            if (dup || jobs.length >= MAX_JOBS) {
                skipped++;
                continue;
            }
            jobs.push({ "id": id++, "device": device, "path": path, "state": QUEUED, "progress": null, "reason": "" });
        }
    }
    return { "state": { "jobs": jobs, "history": state.history, "nextId": id }, "skipped": skipped };
}

// Ids to start now: the first queued job of every device that has none
// sending, so one transfer per device at a time and devices in parallel.
function startable(state) {
    const busy = new Set(state.jobs.filter(j => j.state === SENDING).map(j => j.device));
    const ids = [];
    for (const job of state.jobs) {
        if (job.state === QUEUED && !busy.has(job.device)) {
            busy.add(job.device);
            ids.push(job.id);
        }
    }
    return ids;
}

function _patch(state, id, change) {
    return { "jobs": state.jobs.map(j => j.id === id ? Object.assign({}, j, change) : j), "history": state.history, "nextId": state.nextId };
}

function _find(state, id) {
    return state.jobs.find(j => j.id === id) ?? null;
}

// A finished job leaves the live list for the history, newest first, capped.
function _retire(state, id, change) {
    const job = _find(state, id);
    if (!job)
        return state;
    const closed = Object.assign({}, job, change);
    return {
        "jobs": state.jobs.filter(j => j.id !== id),
        "history": [closed].concat(state.history).slice(0, MAX_HISTORY),
        "nextId": state.nextId
    };
}

function start(state, id) {
    const job = _find(state, id);
    return job && job.state === QUEUED ? _patch(state, id, { "state": SENDING, "progress": null }) : state;
}

// `fraction` 0..1 from rsync, or null for scp: indeterminate, never invented.
function progress(state, id, fraction) {
    const job = _find(state, id);
    if (!job || job.state !== SENDING)
        return state;
    const value = typeof fraction === "number" && isFinite(fraction) ? Math.min(1, Math.max(0, fraction)) : null;
    return _patch(state, id, { "progress": value });
}

function finish(state, id) {
    const job = _find(state, id);
    return job && job.state === SENDING ? _retire(state, id, { "state": DONE, "progress": 1 }) : state;
}

function fail(state, id, reason) {
    const job = _find(state, id);
    return job && job.state === SENDING ? _retire(state, id, { "state": FAILED, "reason": String(reason ?? "") }) : state;
}

// A queued or a sending job. The caller stops the process of a sending one.
function cancel(state, id) {
    const job = _find(state, id);
    return job && (job.state === QUEUED || job.state === SENDING) ? _retire(state, id, { "state": CANCELLED, "progress": null }) : state;
}

// A failed or cancelled job of the history goes back to the end of the queue.
function retry(state, id) {
    const old = state.history.find(j => j.id === id);
    if (!old || (old.state !== FAILED && old.state !== CANCELLED) || state.jobs.length >= MAX_JOBS)
        return state;
    const job = Object.assign({}, old, { "state": QUEUED, "progress": null, "reason": "" });
    return {
        "jobs": state.jobs.concat([job]),
        "history": state.history.filter(j => j.id !== id),
        "nextId": state.nextId
    };
}

function cancelAll(state) {
    return state.jobs.reduce((s, j) => cancel(s, j.id), state);
}

function clearHistory(state) {
    return { "jobs": state.jobs, "history": [], "nextId": state.nextId };
}

// Nothing to poll or refresh when no job lives: the view gates its timer on it.
function active(state) {
    return state.jobs.length > 0;
}

function sendingCount(state) {
    return state.jobs.filter(j => j.state === SENDING).length;
}
