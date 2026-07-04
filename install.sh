#!/usr/bin/env bash
#
# install.sh - symlink the dotfiles in this repo into your home directory.
#
# Safe to re-run: existing files/dirs are backed up to a timestamped folder
# before a symlink is created. Already-correct symlinks are left untouched.
#
# Usage:
#   ./install.sh            # link everything
#   ./install.sh --packages # also install packages (packages.txt + aur.txt) & TPM
#   ./install.sh --dry-run  # show what would happen, change nothing
#   ./install.sh --force    # overwrite existing symlinks without backup

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=false
FORCE=false
DO_PACKAGES=false
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --force)    FORCE=true ;;
    --packages) DO_PACKAGES=true ;;
    -h|--help)  sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Each entry: "<path-inside-repo>  ::  <target-in-home>"
# Whole directories are linked as a unit. hyde/ is linked per-item so the
# large, HyDE-managed themes/ directory is never touched.
LINKS=(
  ".config/hypr            :: $CONFIG_HOME/hypr"
  ".config/kitty           :: $CONFIG_HOME/kitty"
  ".config/waybar          :: $CONFIG_HOME/waybar"
  ".config/rofi            :: $CONFIG_HOME/rofi"
  ".config/nvim            :: $CONFIG_HOME/nvim"
  ".config/dunst           :: $CONFIG_HOME/dunst"
  ".config/wlogout         :: $CONFIG_HOME/wlogout"
  ".config/cava            :: $CONFIG_HOME/cava"
  ".config/fastfetch       :: $CONFIG_HOME/fastfetch"
  ".config/starship        :: $CONFIG_HOME/starship"
  ".config/yazi            :: $CONFIG_HOME/yazi"
  ".config/hyde/config.toml:: $CONFIG_HOME/hyde/config.toml"
  ".config/hyde/wallbash   :: $CONFIG_HOME/hyde/wallbash"
  ".tmux.conf              :: $HOME/.tmux.conf"
  # App-launcher entries (linked individually so other .desktop files are untouched)
  ".local/share/applications/tmux.desktop :: $DATA_HOME/applications/tmux.desktop"
  ".local/share/applications/yt-x.desktop :: $DATA_HOME/applications/yt-x.desktop"
)

info()  { printf '\033[0;34m[*]\033[0m %s\n' "$*"; }
ok()    { printf '\033[0;32m[+]\033[0m %s\n' "$*"; }
warn()  { printf '\033[0;33m[!]\033[0m %s\n' "$*"; }

run() {
  if $DRY_RUN; then
    echo "    would run: $*"
  else
    "$@"
  fi
}

# Read a package list file: drop comments (full-line and inline) and blanks,
# keep the first token of each line (the package name).
strip_list() { sed -e 's/#.*//' "$1" | awk '{print $1}' | awk 'NF'; }

install_packages() {
  local pac="$DOTFILES_DIR/packages.txt"
  local aur="$DOTFILES_DIR/aur.txt"
  local helper=""

  if [[ -f "$pac" ]]; then
    info "Installing official packages (packages.txt)"
    # shellcheck disable=SC2046 # intentional word-splitting into package args
    run sudo pacman -S --needed $(strip_list "$pac")
  else
    warn "no packages.txt found; skipping official packages"
  fi

  for h in paru yay; do command -v "$h" >/dev/null 2>&1 && { helper="$h"; break; }; done
  if [[ -f "$aur" ]]; then
    if [[ -n "$helper" ]]; then
      info "Installing AUR packages ($helper, aur.txt)"
      # shellcheck disable=SC2046 # intentional word-splitting into package args
      run "$helper" -S --needed $(strip_list "$aur")
    else
      warn "no AUR helper (paru/yay) found; skipping aur.txt"
      warn "install one first, e.g.: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
    fi
  fi

  # tmux plugin manager (needed by ~/.tmux.conf)
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    ok "tpm already present"
  else
    info "Bootstrapping tmux plugin manager (TPM)"
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

link_one() {
  local src="$1" dest="$2"
  local abs_src="$DOTFILES_DIR/$src"

  if [[ ! -e "$abs_src" ]]; then
    warn "skip (missing in repo): $src"
    return
  fi

  # Already the correct symlink? Nothing to do.
  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$abs_src")" ]]; then
    ok "ok: $dest"
    return
  fi

  run mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if $FORCE; then
      run rm -rf "$dest"
    else
      run mkdir -p "$BACKUP_DIR/$(dirname "$src")"
      run mv "$dest" "$BACKUP_DIR/$src"
      warn "backed up existing $dest -> $BACKUP_DIR/$src"
    fi
  fi

  run ln -s "$abs_src" "$dest"
  ok "linked: $dest -> $abs_src"
}

info "Dotfiles: $DOTFILES_DIR"
info "Config home: $CONFIG_HOME"
$DRY_RUN && warn "DRY RUN - no changes will be made"

if $DO_PACKAGES; then
  install_packages
  echo
fi

for entry in "${LINKS[@]}"; do
  src="${entry%%::*}"; dest="${entry##*::}"
  # trim surrounding whitespace
  src="$(echo "$src" | xargs)"; dest="$(echo "$dest" | xargs)"
  link_one "$src" "$dest"
done

echo
ok "Done."
if [[ -d "$BACKUP_DIR" ]] && ! $DRY_RUN; then
  info "Replaced files were backed up to: $BACKUP_DIR"
fi
