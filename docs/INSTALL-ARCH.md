# 🐧 Arch Linux + HyDE + halcyon — Full Install Guide

A from-scratch walkthrough: install a **minimal** Arch Linux, layer on **HyDE**, then apply
**halcyon**. Copy/paste friendly.

> **Versions at time of writing** (Arch is rolling — newer is fine):
>
> | Component | Version |
> |---|---|
> | Arch ISO | **2026.06.01** |
> | Linux kernel | **7.0.10** (LTS `6.18.33` available) |
> | pacman | **7.1** |
> | archinstall (guided TUI) | **3.0.15** |
>
> Always grab the **latest** ISO from <https://archlinux.org/download/> — the snapshot date
> only affects the starting point; everything updates via `pacman -Syu` afterwards.

---

## 0. Before you start

- A **UEFI** machine, ≥ 2 GB RAM, ≥ 20 GB disk.
- A USB stick (≥ 2 GB) for the installer.
- ⚠️ **Back up your data** — installing wipes the target disk.

### Create the bootable USB

Download `archlinux-2026.06.01-x86_64.iso`, then:

**From Linux:**
```bash
sudo dd if=archlinux-2026.06.01-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
(Replace `/dev/sdX` with your USB device from `lsblk` — **not** a partition like `sdX1`.)

**From Windows:** use [Rufus](https://rufus.ie/) or [balenaEtcher](https://etcher.balena.io/) (DD mode).

Boot the USB (disable Secure Boot in BIOS if it won't boot) and choose
*"Arch Linux install medium"*.

---

## 1. Connect to Wi‑Fi (CLI) on the live ISO

Wired Ethernet works automatically — skip to step 2. For Wi‑Fi, use **`iwctl`**:

```bash
iwctl
```
Inside the `iwd` prompt:
```text
[iwd]# device list                              # find your adapter, e.g. wlan0
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks               # list SSIDs
[iwd]# station wlan0 connect "Your-SSID"        # it will prompt for the password
[iwd]# exit
```
Verify connectivity:
```bash
ping -c 3 archlinux.org
```

Sync the clock:
```bash
timedatectl set-ntp true
```

---

## 2. Refresh keyring (recommended)

Avoids signature errors if the ISO is a little old:
```bash
pacman -Sy archlinux-keyring
```

---

## 3. Install the base system with `archinstall` (guided TUI)

`archinstall` is the official guided installer bundled on the ISO. Launch it:

```bash
archinstall
```

Work through the menu top‑to‑bottom. Recommended choices for a **minimal** base that
HyDE will build on:

| Menu option | Recommended choice |
|---|---|
| **Archinstall language** | English |
| **Mirrors / region** | Your country (faster downloads) |
| **Locales** | Keyboard + language to taste (`en_US.UTF-8` is safe) |
| **Disk configuration** | *Best-effort default* → select disk → **wipe** → filesystem **ext4** (or **btrfs** for snapshots) |
| **Disk encryption** | Optional (LUKS) — skip if unsure |
| **Bootloader** | **systemd-boot** (UEFI) or GRUB |
| **Swap** | On (zram) |
| **Hostname** | e.g. `arch` |
| **Root password** | set one |
| **User account** | create your user, tick **"is superuser / sudo"** |
| **Profile** | **Minimal** ← *no desktop environment; HyDE installs the desktop later* |
| **Audio** | **Pipewire** |
| **Kernels** | **`linux-lts`** (stable, recommended primary) — optionally also tick `linux` as a fallback |
| **Network configuration** | **NetworkManager** ← important, HyDE/Wi‑Fi rely on it |
| **Additional packages** | `git base-devel wget nano` (minimal helpers) |
| **Timezone** | your zone |

Then select **Install**. When it finishes, decline the chroot prompt (or `exit`), then:

```bash
reboot
```
Remove the USB during reboot.

---

## 4. First boot — network + full update

Log in as your user. Bring up Wi‑Fi via NetworkManager (CLI):

```bash
nmcli radio wifi on
nmcli device wifi list
nmcli device wifi connect "Your-SSID" password "Your-Password"
```
(Or run `nmtui` for a simple text UI.)

Update everything first:
```bash
sudo pacman -Syu
```

---

## 5. Install an AUR helper (`yay`)

HyDE and many extras live in the AUR:
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd .. && rm -rf yay
```

---

## 6. Install HyDE (the base desktop)

HyDE's installer pulls in **Hyprland**, Waybar, rofi, dunst, kitty, theming, etc.

```bash
pacman -Q git base-devel >/dev/null 2>&1 || sudo pacman -S --needed git base-devel
git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts
./install.sh
```
Follow the prompts. When done, **reboot** and log into **Hyprland** (pick it at the
display manager, or it autostarts depending on your setup).

> At this point you have a fully working HyDE desktop. halcyon just personalizes it.

---

## 7. Install halcyon (this rice)

```bash
git clone https://github.com/sm60786/halcyon-rice ~/halcyon
cd ~/halcyon
./install.sh --packages
```
`install.sh` symlinks the configs into `~/.config` and **backs up** anything it replaces
to `~/.dotfiles-backup/<timestamp>/`. Re-runnable any time.

The **`--packages`** flag also installs the extra tools halcyon uses on top of HyDE
(from `packages.txt` + `aur.txt`) and bootstraps the tmux plugin manager (TPM):

- **pacman:** `tmux`, `yazi` (+ preview helpers), `yt-dlp`, `mpv`, `swappy`
- **AUR:** `yt-x` (needs `paru`/`yay`)
- **TPM:** cloned to `~/.tmux/plugins/tpm` (then in tmux press `prefix + I` to install plugins)

Run plain `./install.sh` (no flag) to only symlink configs without touching packages.
Preview everything first with `./install.sh --packages --dry-run`.

Reload Hyprland (`Super + Shift + R`) or log out/in.

### After install — review these machine-specific files
- `~/.config/hypr/monitors.conf` — set your own display layout (`hyprctl monitors` to list).
- `~/.config/hypr/nvidia.conf` — only relevant on NVIDIA GPUs.

---

## Quick reference (the whole thing, condensed)

```bash
# --- live ISO ---
iwctl                      # connect Wi-Fi (station <dev> connect "SSID")
timedatectl set-ntp true
pacman -Sy archlinux-keyring
archinstall                # Profile=Minimal, Network=NetworkManager, Audio=Pipewire
reboot

# --- first boot ---
nmcli device wifi connect "SSID" password "PW"
sudo pacman -Syu

# --- AUR helper ---
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay

# --- HyDE ---
git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts && ./install.sh && reboot

# --- halcyon (configs + extra packages + TPM) ---
git clone https://github.com/sm60786/halcyon-rice ~/halcyon
cd ~/halcyon && ./install.sh --packages
```

---

## Troubleshooting

- **No internet on live ISO:** double-check `station <dev> get-networks`; some adapters
  show as `wlan1`. `rfkill unblock all` if the radio is soft-blocked.
- **`archinstall` mirror errors:** pick your region under *Mirrors* before installing.
- **Black screen / no wallpaper after HyDE:** ensure the wallpaper backend is running
  (`swww query`); HyDE uses **swww** by default.
- **Pacman keyring / signature errors:** `sudo pacman -Sy archlinux-keyring && sudo pacman -Syu`.
