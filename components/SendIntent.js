.pragma library

// Reads a launcher query as a request to send a file ("send file to vega",
// "envoie un fichier au nas", "envoyer à nas"), French or English. Pure: the
// launcher turns the answer into an entry. It must stay silent for every
// other search — a timer, an app name, a sentence for Sands — so the grammar
// is strict: the WHOLE query must be consumed, or it is not ours.
//
//   claim("send a file to vega", peers) -> { device: "vega" }
//   claim("send file", peers)           -> { device: null }
//   claim("timer 20 min", peers)        -> null

// Nobody types more than this to send a file; the cap keeps a pasted text
// from costing anything on every keystroke (value 11)
const MAX_INPUT = 80;
const MAX_TOKENS = 8;

const VERB = ["send", "envoie", "envoies", "envoyer", "envoyez", "envoi"];
const NOUN = ["file", "files", "fichier", "fichiers", "document", "documents"];
const DETERMINER = ["a", "an", "the", "some", "my", "un", "une", "le", "la", "les", "des", "mon", "ma", "mes"];
const PREPOSITION = ["to", "a", "au", "aux", "vers", "pour"];

// Lower case, no accents, words separated by single spaces
function _words(text) {
    return String(text).normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
        .replace(/[^a-z0-9]+/g, " ").trim().split(" ").filter(w => w);
}

// The peer a typed name stands for: exact first, then a unique prefix.
// Unknown or ambiguous: null, never a guess
function _peer(name, peers) {
    if (!name)
        return null;
    const named = (peers || []).map(p => ({ "name": p.name, "key": _words(p.name).join(" ") })).filter(p => p.key);
    const exact = named.filter(p => p.key === name);
    if (exact.length)
        return exact.length === 1 ? exact[0].name : null;
    const prefixed = named.filter(p => p.key.indexOf(name) === 0);
    return prefixed.length === 1 ? prefixed[0].name : null;
}

// { device: <peer name or null> } when the query asks to send a file, else null
function claim(query, peers) {
    const text = String(query === undefined || query === null ? "" : query);
    if (text.length > MAX_INPUT)
        return null;
    const w = _words(text);
    if (w.length < 2 || w.length > MAX_TOKENS || VERB.indexOf(w[0]) < 0)
        return null;
    let i = 1;
    // "send (a) file (to vega)"
    if (DETERMINER.indexOf(w[i]) >= 0)
        i++;
    if (NOUN.indexOf(w[i]) >= 0) {
        i++;
        if (i === w.length)
            return { "device": null };
        if (PREPOSITION.indexOf(w[i]) < 0)
            return null;
        // "to the nas": the article is dropped, unless it starts the name
        const target = w.slice(i + 1);
        const bare = DETERMINER.indexOf(target[0]) >= 0 ? _peer(target.slice(1).join(" "), peers) : null;
        return { "device": _peer(target.join(" "), peers) || bare };
    }
    // "send to vega": the verb, then a known peer — and only a known peer
    if (PREPOSITION.indexOf(w[1]) >= 0 && w.length > 2) {
        const device = _peer(w.slice(2).join(" "), peers);
        return device ? { "device": device } : null;
    }
    return null;
}
