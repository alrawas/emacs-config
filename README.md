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

## Features

- Evil mode (Vim keybindings)
- Elpaca package manager
- General.el for keybindings
- Vterm terminal emulator
- Projectile project management
- Ivy/Counsel completion
- Org mode with GTD workflow
