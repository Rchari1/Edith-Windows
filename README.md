<p align="center">
  <img src="assets/icon.png" alt="Edith" width="132" height="132">
</p>

<h1 align="center">Edith Second Brain for Windows</h1>

<p align="center"><strong>A second brain for AI.</strong></p>

<p align="center">
  <a href="https://edithapp.ai">edithapp.ai</a> &middot;
  <a href="https://github.com/Rchari1/Edith-SecondBrain">the macOS version</a>
</p>

The Windows build of [Edith Second Brain](https://github.com/Rchari1/Edith-SecondBrain).
Every change is installed, tested and packaged on Windows by CI. Found something off?
[Open an issue](https://github.com/Rchari1/Edith-Windows/issues).

## Install

**[Download the installer](https://github.com/Rchari1/Edith-Windows/releases/latest)**, built on
Windows by CI. You also need [Claude Code](https://claude.com/claude-code), in the terminal or the
VS Code extension.

**Windows will stop you the first time.** You get a blue screen saying *"Windows protected your PC"*.
Click **More info**, then **Run anyway**. That happens because the installer carries no code signing
certificate - it costs a few hundred dollars a year - not because anything is wrong with the file.
The release notes list its SHA-256 if you want to check it.

### Or build it yourself

You need [Node.js](https://nodejs.org) 22.12 or newer **and a C++ compiler**: install
[Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) with the
"Desktop development with C++" workload. The database module compiles during install, and without it
you get `Could not find any Visual Studio installation to use`.

```bash
git clone https://github.com/Rchari1/Edith-Windows.git
cd Edith-Windows
npm install
npm run dist:win
```

The installer lands in `release/`.


## What it does

- **No API key. No account. No inference.** Claude reads and writes your notes through its own session, on the plan you already pay for. Edith is the store and the canvas.
- **Claude fills it for you.** Ask *"review my recent sessions and save anything worth keeping"* and Claude reads your transcripts with `list_sessions` / `read_session`, then writes the notes back with `save_note`.
- **Serves Claude over MCP.** `search_brain`, `read_note`, `list_notes`, and `save_note`. Claude both reads from and writes to the brain mid-session.
- **Shows you the retrieval.** A search dims-glows what Claude *considered*; opening a note brightly glows what it actually *used*. Highlights fade over 30 seconds.
- **Mini mode beside your session.** Minimize Edith and it becomes a narrow panel docked to the left edge of the screen, drawing your brain and lighting up the notes Claude reaches for - the window and the panel are never up at the same time. With the window closed or minimized, the panel also opens on its own when a Claude session starts. It never takes focus, folds to a strip the width of the rail or shrinks to a small square in the corner - both just the live graph - and stays closed for the rest of a session once you close it. Turn off the automatic opening under **Connection**.
- **Takes your own content too.** **Add content** imports `.md`, `.markdown`, `.txt`, and `.mdx` files, or anything you paste. Files keep their existing frontmatter, so importing a Markdown vault preserves ids and links instead of duplicating notes. Import as written, or distil into concepts.
- **Plain Markdown.** Files on disk are the source of truth. Edit them in any editor. Delete the index and it rebuilds.

### What happens on first launch

Edith starts its brain server on `127.0.0.1:4319` and connects itself to Claude. There is no account and no API key: ask Claude to *"review my recent sessions and save anything worth keeping"* and it fills the brain itself.

Outside its own folder, Edith adds:

| What | Where |
|---|---|
| Its server entry, so Claude can reach the brain | `%USERPROFILE%\.claude.json`, plus `%APPDATA%\Claude\claude_desktop_config.json` if you have Claude Desktop |
| A session-start hook that tells Claude the brain exists | `%USERPROFILE%\.claude\settings.json` |
| The `/edith` command | `%USERPROFILE%\.claude\skills\edith` |
| A handful of starter skills | `%USERPROFILE%\.claude\skills\`, managed from the Skills panel |

Your notes are plain Markdown in `%APPDATA%\Edith\vault`.

### Updating

Quit Edith, then run the newer installer over the top. Your notes and settings stay where they are.

### Troubleshooting

- **Edith quits the moment it opens.** If you launched it from a VS Code terminal, open it from the Start menu instead - VS Code's terminal sets an environment variable that stops the app from starting.
- **The window buttons look wrong.** Open an issue with a screenshot and your Windows version.
- **Claude never uses the brain.** Restart Claude Code after Edith's first launch, then open **Connection** in Edith and check that the session primer says installed.

### Uninstalling

Uninstall Edith from **Settings > Apps > Installed apps**. Then remove what it added: the `edith` entry under `mcpServers` in `%USERPROFILE%\.claude.json`, the hook in `%USERPROFILE%\.claude\settings.json` whose command contains `edith:session-context`, the `%USERPROFILE%\.claude\skills\edith` folder, and any starter skills you no longer want. Your notes stay in `%APPDATA%\Edith` until you delete that folder too.

## How it works

| Stage | What happens |
|---|---|
| **Watch** | `chokidar` on `%USERPROFILE%\.claude\projects`, waiting for a session to go quiet |
| **Parse** | JSONL to a canonical `Session`, following `leafUuid` to skip abandoned branches |
| **Store** | Markdown + YAML frontmatter, indexed in SQLite FTS5 |
| **Serve** | In-process MCP server over local HTTP |
| **Light up** | Every tool call emits an event straight to the renderer |

### Tools Claude gets

| Tool | What it does |
|---|---|
| `search_brain` | Search the notes |
| `read_note` | Read one note in full |
| `list_notes` | See what the brain holds |
| `save_note` | Write an insight back |
| `list_sessions` | See past Claude sessions, and which are already captured |
| `read_session` | Read one transcript, tool noise stripped |

The last two are what let Claude do the distilling itself, on your plan, with no key anywhere.

Edith hosts the MCP server *itself* rather than spawning it. That is what makes the highlighting instant: a tool call and the glow are the same tick.

### Adding your own content

**Add content** in the sidebar opens an import dialog with two modes:

| Mode | What it does | Cost |
|---|---|---|
| Keep as written | Stores the file or text verbatim as a note | free |
| Distil into concepts | Runs the same extraction used on sessions | one API call |

Re-importing a file **deepens** the existing note rather than creating a duplicate, so syncing a folder repeatedly is safe. A file with broken frontmatter loses its metadata, not its content.

### Note format

```markdown
---
id: dynamic-port-binding
title: Dynamic Port Binding
type: concept
created: 2026-08-25
updated: 2026-08-25
origin: distilled
sources:
  - session: 11111111-2222-3333-4444-555555555555
    project: -Users-u-myapp
    at: 2026-08-25T10:00:00Z
links: [mcp-registration]
---
Bind the next free port and rewrite the MCP config to match.
```

Every note records the sessions it came from. That provenance is written from day one, so tracing a concept back to its conversations is a view rather than a migration.

## Things worth knowing

**Upgrading from the old name.** Edith was previously called SecondBrain. On first launch it copies your existing vault and settings across from the old location, and replaces the stale `secondbrain` entry in `~/.claude.json` with `edith` so Claude does not see two identical tool sets. The old directory is left untouched as a fallback.


**An API key does not give access to claude.ai history.** The Messages API is stateless; there is no endpoint listing past conversations. Edith reads Claude Code's local transcripts. The API key is used only to distill them.

**Most `.jsonl` files under `~/.claude/projects` are not sessions.** Subagent and workflow transcripts nest under session directories and typically outnumber real sessions by roughly 9:1. Edith classifies by path shape so they never become notes.

**Transcripts are trees.** Interrupting Claude forks the history and leaves the abandoned branch in the file. The parser walks back from `last-prompt.leafUuid` so only what actually happened gets distilled.

**Your config is safe.** Registration merges a single key into `~/.claude.json`, writes atomically, and backs the file up before first modification.

## Development

```bash
npm run dev        # run the app with hot reload
npm test           # 239 tests
npm run typecheck  # tsc --noEmit
npm run build      # bundle main, preload, renderer
npm run dist:win   # build the Windows installer into release/
npm run icon       # rebuild the macOS icon set; assets/icon.ico is built from assets/icon.png
```

Tests cover path classification, fork resolution, malformed-line tolerance, vault merge semantics, config-write safety, a live MCP client over HTTP, and the full pipeline end to end with the API call mocked.

## Keeping up with the macOS repo

Same codebase, with the platform differences kept to as few files as possible:

| What | Why |
|---|---|
| The Claude Code hook puts its marker in the URL | `cmd` has no `#` comment and no `true` |
| The status line is PowerShell, not Python | Windows ships PowerShell; batch cannot parse the JSON Claude sends |
| Edith's drawn window buttons are hidden | Windows draws its own title bar, so ours would be a second set |
| A `win` build target and an `.ico` | electron-builder needs both to make an installer |
| Two test assertions skip | They check the Unix executable bit, which NTFS does not have |

Fixes from the macOS repo come in with:

```bash
git remote add upstream https://github.com/Rchari1/Edith-SecondBrain.git   # once
git fetch upstream && git merge upstream/main
```

## Not in v1

claude.ai export import - session-layer graph rendering - cross-machine sync - semantic search. Search sits behind a `SearchProvider` interface, so adding hybrid retrieval later touches one file.

## License

Edith is source-available under the [Functional Source License, Version 1.1, MIT Future License](LICENSE) (FSL-1.1-MIT). You can read, use, modify and share it for anything except offering it, or something substantially similar, as a competing commercial product or service. Each release becomes MIT-licensed two years after it is published.

© 2026 Raghav Chari and Kate Bonner.
