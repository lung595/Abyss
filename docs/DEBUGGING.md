# Debugging Abyss

For someone who has a problem and wants to tell the maintainer about it without giving anything personal away.

> The report is built by the `diagnostics/` module. This page describes what it holds and its event codes; the buttons and commands that ask for it come in a later release.

## Contents

- [What the report holds](#what-the-report-holds)
- [Reading the journal yourself](#reading-the-journal-yourself)
- [The event codes](#the-event-codes)
- [Cases](#cases)

## What the report holds

An anonymous text you read before you paste it into a GitHub issue. Abyss never sends it anywhere: it stays on your machine until you decide to share it.

- **In it:** the time (UTC), the versions of Abyss, DMS, Quickshell, Qt and niri, the distribution, which surfaces are active, the settings that choose a behaviour, a few counts (peers, groups, timers, helper programs running), the shell's CPU over one second, the last events Abyss recorded and the lines Abyss left in the DMS journal.
- **Never in it:** a peer name, a NetBird address or host name, your login, an SSH user, a file or folder of yours (anything under your home folder except hidden config folders, or on a mounted drive), your login inside a path, a setup key, a token or any text you typed. Events are built from a fixed list of codes and words; whatever else reaches them is replaced by `?`, and every line is cleaned a second time before it is kept.
- **Not kept:** the events live in memory, at most 200, and vanish with the shell (a restart, a crash, a log out). Nothing is written to disk and nothing runs while nobody asks for a report.

The CPU figure is the **whole shell** (DMS and every plugin together) over one second, measured only when a report is built. The shell is one process, so Abyss's own share cannot be told apart from it.

## Reading the journal yourself

Errors and warnings are written to the DMS journal with the tag `[abyss]`:

```sh
journalctl --user -u dms -n 300 --no-pager | grep '\[abyss\]'
```

Read the lines before you paste them: the shell's own messages can name folders under your home folder.

## The event codes

A code is `ABY-` followed by a level letter (`E` error, `W` warning, `I` info, `D` debug) and a number. Errors and warnings reach the journal; info and debug stay in memory. A code's number never changes meaning once released.

| Code | Level | Meaning | Fields |
|---|---|---|---|
| `ABY-E001` | error | Reading the mesh from NetBird failed | `reason` |
| `ABY-E002` | error | A peer action (connect, disconnect, ping, ssh, send, wake, exit, share_ssh, join) failed | `action`, `reason` |
| `ABY-E003` | error | A helper program (`netbird`, `ip`, `ssh`, `scp`, `ping`, `wakeonlan`, `xdg-open`, `wl_copy`, `dms`, `sh`) stopped unexpectedly | `tool`, `code` (its exit status) |
| `ABY-E004` | error | Sending a file failed | `reason` |
| `ABY-W010` | warning | NetBird is not usable (missing, stopped, signed out) | `state` |
| `ABY-W011` | warning | A helper program is missing | `tool` |
| `ABY-I020` | info | A surface (widget, control center, desktop, daemon, launcher, settings) was loaded | `surface` |
| `ABY-I021` | info | A surface was unloaded | `surface` |
| `ABY-I030` | info | A diagnostic report was requested | `via` |
| `ABY-D040` | debug | The scene changed state (hidden, visible, ambient) | `state`, `count` |

The words a field may hold are listed in `diagnostics/Codes.js`; a test fails when a code is missing from this table.

## Cases

### The widget shows no peers

Look for `ABY-W010` (NetBird missing, stopped or signed out) and `ABY-E001` (the mesh could not be read) in your report.

### An action on a peer does not work

`ABY-E002` names the action and why it failed (`timeout`, `refused`, `not_found`, `offline`...).

### A helper program keeps stopping

`ABY-E003` names the program (`tool`) and its exit status (`code`); `ABY-W011` says it is not installed.

### The shell restarts or the bar freezes

The memory buffer is lost with the shell, so the report right after a restart is empty. Quickshell keeps its own crash folder under `~/.cache/quickshell/crashes/`; it contains paths with your login, so read it before sharing any of it. Abyss keeps no trace on disk.
