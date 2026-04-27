# setupscripts

A grab-bag of small, re-runnable helper scripts for setting up and tweaking Linux workstations and servers – the kind of thing you'd otherwise paste into a fresh machine from a notes file.

Each script is self-contained, idempotent, and safe to re-run. Run them directly; there's no installer or orchestration layer.

## Scripts

| Script | What it does |
| --- | --- |
| [`fix-inotify-watches.sh`](./fix-inotify-watches.sh) | Bumps kernel inotify limits so editors (Sublime, VS Code, JetBrains, nvim) can watch large projects without silently dropping events. Persists via `/etc/sysctl.d/90-inotify.conf` and applies live. |

## Usage

Clone the repo, then run whichever script you need:

```sh
git clone https://github.com/matcluck/setupscripts.git
cd setupscripts
./fix-inotify-watches.sh
```

Scripts that need root will re-exec themselves under `sudo`.

## Conventions

- Bash, `set -euo pipefail`, no external runtime dependencies beyond standard coreutils
- Idempotent – re-running a script should converge to the same end state, not stack changes
- A header comment at the top of each script explains what it does, why, and what it touches
- Tested on Debian/Ubuntu; most should work on any modern Linux

## Contributing

New scripts are welcome as long as they fit the "small, generic, re-runnable" shape. Add an entry to the table above when you add one.

## Licence

MIT – see [`LICENSE`](./LICENSE).
