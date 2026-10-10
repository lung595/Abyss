// The phrases both launcher providers must keep apart: Abyss' "send a file"
// sentences and Sands' timer sentences. tests/sendIntent.test.js checks both
// directions: Abyss claims none of the timer phrases, Sands finds no timer in
// the Abyss phrases.

// Abyss: phrase -> the device it names (null = none). "vega" and "nas" are peers
const SEND = [
    ["send file", null],
    ["send a file", null],
    ["send files", null],
    ["send file to vega", "vega"],
    ["Send a file to Vega", "vega"],
    ["send the file to nas", "nas"],
    ["send a document to nas", "nas"],
    ["send file to ve", "vega"],
    ["send file to unknown", null],
    ["send file to n", null],
    ["send file to", null],
    ["send to vega", "vega"],
    ["send to nas", "nas"],
    ["envoie un fichier", null],
    ["envoyer un fichier", null],
    ["envoi fichier", null],
    ["envoie un fichier au nas", "nas"],
    ["envoie un fichier à vega", "vega"],
    ["envoyer des fichiers vers vega", "vega"],
    ["envoie le document pour nas", "nas"],
    ["envoyer à nas", "nas"],
    ["envoyer a vega", "vega"],
    ["ENVOIE UN FICHIER AU NAS", "nas"]
];

// Abyss: queries that name no file; neither provider's business here
const PLAIN = ["send", "envoyer", "file", "fichier", "vega", "send to", "send mail", "send to unknown", "send nas",
    "firefox", "settings", "my-nas", "a file", "the file to vega", "abyss", "send file now please", "send a big file to vega today"];

// Sands: phrases that are timers and must never become a send entry
const TIMERS = [
    "20 min",
    "timer 20 min pâtes",
    "timer 20 min",
    "1h30",
    "25m pasta",
    "dans 10 minutes",
    "in 5 minutes",
    "à 18h",
    "at 6pm",
    "réveille-moi à 7h",
    "wake me at 7",
    "alarme 7h30",
    "rappel envoyer le dossier dans 10 min",
    "rappel envoyer le fichier dans 10 min",
    "reminder send the file in 10 minutes",
    "remind me to send the file in 2 hours",
    "timer envoyer le fichier 10 min",
    "minuteur 15 minutes",
    "4x 1h",
    "countdown 90 seconds"
];
