# ARAWAS GNU Emacs Config

Personal Emacs configuration using literate programming with `org-babel`.

## System Dependencies

Install these before launching Emacs:

### Ubuntu/Debian
```bash
sudo apt install cmake libtool-bin libvterm-dev
```

### Fedora
```bash
sudo dnf install cmake libtool libvterm-devel
```

### Arch
```bash
sudo pacman -S cmake libtool libvterm
```

## Installation

1. Clone this repo to your Emacs config directory:
   ```bash
   git clone git@github.com:alrawas/emacs-config.git ~/.config/emacs
   ```

2. Install system dependencies (see above)

3. Launch Emacs - packages will auto-install via Elpaca on first run

4. Restart Emacs after initial package installation completes

## Structure

- `init.el` - Entry point, loads config.org via org-babel
- `early-init.el` - Early initialization (disables package.el)
- `config.org` - Main literate configuration (source of truth)
- `config.el` - Tangled output from config.org (auto-generated)
- `scripts/` - Custom elisp modules
- `themes/` - Custom themes

## Running as Server/Client

This config is designed to run Emacs as a daemon for instant startup:

```bash
# Start the daemon (once, or add to autostart)
emacs --daemon

# Connect with emacsclient
emacsclient -c           # New GUI frame
emacsclient -t           # Terminal frame
emacsclient -c file.txt  # Open file in new frame
```

To auto-start the daemon on login, create a systemd user service:

```bash
# ~/.config/systemd/user/emacs.service
[Unit]
Description=Emacs Daemon

[Service]
Type=forking
ExecStart=/usr/bin/emacs --daemon
ExecStop=/usr/bin/emacsclient --eval "(kill-emacs)"
Restart=on-failure

[Install]
WantedBy=default.target
```

Then enable with: `systemctl --user enable --now emacs`

## Features

- Evil mode (Vim keybindings)
- Elpaca package manager
- General.el for keybindings
- Vterm terminal emulator
- Projectile project management
- Ivy/Counsel completion
- Org mode with GTD workflow
