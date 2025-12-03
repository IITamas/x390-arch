# ThinkPad X390 - Arch + Sway Setup

Opinionated, reproducible setup for a ThinkPad X390:
- Sway + Waybar (light theme)
- Alacritty, Firefox (Wayland + VA-API), VSCodium
- PipeWire audio, NetworkManager, Bluetooth (blueman)
- caps2esc (tap Esc / hold Ctrl), natural touchpad
- US/HU keyboard layouts (Alt+Shift), toggle: Win+Alt+k
- TLP balanced profile, Intel power savings

## Structure

- `config/` — all configuration files (single flat dir, no nesting)
- `*.sh` — modular install/apply scripts
- `state.sh` — state tracking (checksums, rollback metadata)
- `test.sh` — preflight config validation

## Requirements

- Arch Linux (with sudo)
- Internet (to install packages/AUR)
- `jq`, `git`, `makepkg` (installed by scripts if missing)
- Optional: `yamllint` for YAML validation

## Usage

```bash
git clone <this-repo> x390-setup
cd x390-setup
chmod +x *.sh
./main.sh
```

The script:
1. Validates all configs (`./test.sh all`)
2. Exits immediately if tests fail
3. Installs packages and applies configs
4. Is idempotent (only updates when configs change)

## Update Workflow

- Edit files under `config/`
- Run `./test.sh all`
- Run `./main.sh`

## Keyboard

- Layouts: `us,hu` with `Alt+Shift` toggle
- Extra toggle: `Win+Alt+k` with notification
- Waybar shows current layout

## Rollback

State files are tracked in `.state/`. If a config breaks, restore the previous version manually from `.state/rollback/`.

## Notes

- Firefox VA-API prefs are appended to `user.js` in your default profile on first run.
- Greetd with `tuigreet` logs directly into Sway.
- Scripts fail fast; fix failing tests before running main.