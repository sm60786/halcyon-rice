# dotfiles

My personal Linux rice — a [Hyprland](https://hypr.land) setup built on top of the
[HyDE](https://github.com/HyDE-Project/HyDE) framework on Arch Linux.

This repo tracks the configs I actually edit and lets me restore them on any
machine with a single script. Everything is symlinked back into `~/.config`, so
once installed you edit files here and the changes are live.

> [!NOTE]
> This sits **on top of HyDE**. Install HyDE first; these files override/extend
> it. The large, HyDE-managed `~/.config/hyde/themes/` directory is intentionally
> not tracked here.

## What's inside

| Path | Tool |
|------|------|
| `.config/hypr` | Hyprland (keybindings, window rules, hyprlock, hypridle, animations…) |
| `.config/waybar` | Status bar |
| `.config/rofi` | App launcher / menus |
| `.config/kitty` | Terminal |
| `.config/dunst` | Notifications |
| `.config/wlogout` | Logout menu |
| `.config/nvim` | Neovim config |
| `.config/cava` | Audio visualizer |
| `.config/fastfetch` | System info on shell start |
| `.config/starship` | Shell prompt |
| `.config/hyde/config.toml`, `.config/hyde/wallbash` | HyDE per-user settings & wallbash templates |

## Requirements

- Arch Linux (or derivative)
- [Hyprland](https://hypr.land) `>= 0.55`
- [HyDE](https://github.com/HyDE-Project/HyDE) installed
- The tools you want to use: `waybar`, `rofi`, `kitty`, `dunst`, `wlogout`,
  `neovim`, `cava`, `fastfetch`, `starship`

## Install

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# Preview what would change (recommended first run):
./install.sh --dry-run

# Create the symlinks (existing files are backed up automatically):
./install.sh
```

Anything that already existed is moved to `~/.dotfiles-backup/<timestamp>/`
before a symlink is created, so nothing is lost.

### Options

| Flag | Effect |
|------|--------|
| `--dry-run` | Show planned actions without changing anything |
| `--force` | Overwrite existing symlinks without creating a backup |

## Updating

Because configs are symlinked, just edit normally, then:

```bash
cd ~/dotfiles
git add -A
git commit -m "tweak: <what changed>"
git push
```

## Credits

- [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) — the base framework.
- The Hyprland community.

## License

[MIT](./LICENSE)
