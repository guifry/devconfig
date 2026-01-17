# Unix Tools

Tools to install on all machines.

## CopyQ (clipboard manager)

Clipboard history with global hotkey access.

**macOS:**
```bash
brew install copyq
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install copyq
```

**Linux (Arch):**
```bash
sudo pacman -S copyq
```

**Config:**
- Set global hotkey to `Cmd+Option+V` (mac) / `Ctrl+Alt+V` (linux)
- Preferences → Shortcuts → Show/hide main window

## Claude Code (AI coding assistant)

Anthropic's agentic CLI for coding tasks.

**macOS/Linux (native binary - recommended):**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Via npm (requires Node 18+):**
```bash
npm install -g @anthropic-ai/claude-code
```

**Verify:**
```bash
claude doctor
```

**Usage:**
```bash
cd your-project
claude
```
