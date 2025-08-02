# VICE Pi Compile Makefile

This Makefile automates downloading, building, and installing the VICE emulator on Raspberry Pi OS (Lite or Desktop), and provides additional setup for Samba file sharing, auto-login, auto-starting VICE, and hiding the rainbow splash screen.

## Prerequisites

- Raspberry Pi OS (Lite or Desktop)
- `sudo` privileges
- Internet connection

## Usage

Open a terminal in this directory and run:

```bash
make
```

This will:
- Install all build dependencies
- Download and extract VICE
- Build and install VICE
- Set up a Samba share with subfolders for disks and roms
- (Optionally) Enable auto-login and auto-start of VICE
- (Optionally) Hide the rainbow splash screen

## Available Targets

- `make deps`  
  Install all required system packages for building VICE.

- `make download`  
  Download the VICE source tarball.

- `make extract`  
  Extract the downloaded VICE source.

- `make autogen`  
  Run the VICE autogen script.

- `make configure`  
  Configure the VICE build.

- `make build`  
  Build VICE using all available CPU cores.

- `make install`  
  Install VICE to your home directory.

- `make add_config_txt_changes`  
  Add `disable_splash=1` to `/boot/config.txt` or `/boot/firmware/config.txt` to hide the Raspberry Pi rainbow splash screen on boot. The Makefile will check for `/boot/firmware/config.txt` first and use it if present.

- `make samba_setup`  
  Install Samba, create a share at `~/vice-share` with `disks` and `roms` subfolders, and configure permissions.  
  Access from another computer using:  
  `smb://<your-pi-ip-address>/VICE`

- `make autologin_pi`  
  Enable auto-login for the current user (requires Raspberry Pi OS Desktop with LightDM).

- `make autostart_x64sc`  
  Add a command to your `~/.bash_profile` so that `x64sc` launches automatically when you log in on the console (not via SSH).

- `make clean`  
  Remove all downloaded and built files.

## Notes

- The Samba share is created at `~/vice-share` with `disks` and `roms` subfolders for easy file management.
- The `autostart_x64sc` target only affects local console logins, not SSH sessions.
- For headless (Lite) setups, the Makefile is designed to work without a desktop environment.
- If you want VICE to start automatically for all users or in other scenarios, consider using a systemd user service or customizing `/etc/profile`.
- The rainbow splash screen will be hidden on next boot after running `make add_config_txt_changes`.

## Example Workflow

```bash
make
make samba_setup
make autostart_x64sc
make add_config_txt_changes
```

Then reboot your Pi. VICE will auto-launch on console login, and you can access your shared folders from other computers.

---
