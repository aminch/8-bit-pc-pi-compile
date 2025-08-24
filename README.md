
# 8-bit PC Pi Compile

This project **8-bit PC Pi Compile** is a set of makefiles to enable the installation of Vice the Commodore 64 emulator and Atari800 the Atari 8-bit PC emulator on Raspberry Pi OS Lite (64-bit). In addition it installs a `menu` that allow easy switching of the default emulator, easy configuration the main features of the emulators and Pi OS Lite.

It is designed to run best on a Pi500 or Pi400, but of course will work on any Pi 4 or Pi 5.

The goal of the project is to try and keep the feel of these old 8-bit computers by stripping back everything from the OS (hence the use of Pi OS Lite) and booting directly into the emulator. If you use a Pi400 or Pi500 it's as close as possible to to the feel of these old computers with everything in the keyboard!

## Emulator default and additional settings

### Vice (Commodore 64)

### Atari800

### Use of original joysticks

Original joysticks can be connected to the Raspberry Pi GPIO pins using this adapter: https://github.com/aminch/bmc-joy-pcb

All the settings for both the Vice and Atari800 to use the adapter and real joysticks are pre-configured and installed with this makefile. The `menu` also allows for easy change of configurations.

### Installing in original C64 case

It's possible to use a Pi 5B+ in combination with https://github.com/aminch/bmc64-pcb (at least v 2.0.5) installed in an original C64 case, and keyboard.

Details to come...

## Getting Started: Flashing Raspberry Pi OS Lite (64-bit)

1. **Download and Install Raspberry Pi Imager**  
   Get it from [https://www.raspberrypi.com/software/](https://www.raspberrypi.com/software/).

2. **Burn Raspberry Pi OS Lite to SD Card**  
   - Open Raspberry Pi Imager.
   - Choose "Raspberry Pi OS Lite (64-bit)" as the operating system.
   - Select your SD card as the storage device.

3. **Customize Settings Before Writing**  
   - Click the gear icon (⚙️) or "Advanced options" before clicking "Write".
   - Set the hostname if desired.
   - **Set username:** Enter `pi` as the username.
   - **Set password:** Choose a password for the `pi` user.
   - **Configure WiFi:**  
     - Enter your WiFi SSID and password.
     - Set your WiFi country.
   - Save the settings and proceed.

4. **Write the Image**  
   - Click "Write" to burn the image and apply your settings.
   - When finished, insert the SD card into your Raspberry Pi and power it on.

---

## First Boot: Logging In and Cloning This Repository

1. **Log in to your Raspberry Pi**  
   - Use the username `pi` and the password you set in the Imager.
   - You can log in directly on the Pi.

2. **Install git if not already present:**
   ```bash
   sudo apt-get install -y git
   ```


3. **Clone this repository:**
  ```bash
  git clone https://github.com/aminch/8-bit-pc-pi-compile.git
  cd 8-bit-pc-pi-compile
  ```


You are now ready to use the Makefile and scripts as described below.

---


# 8-bit Emulator Compilation and Installation

This Makefile and supporting scripts automate downloading, building, and installing 8-bit emulators (including VICE, and Atari800) on Raspberry Pi OS (Lite or Desktop). It also provides additional setup for Samba file sharing, auto-login, auto-starting emulators, and hiding the rainbow splash screen.

## Prerequisites

- Raspberry Pi OS (Lite or Desktop)
- `sudo` privileges
- Internet connection


## Usage

Open a terminal in this directory and run:

```bash
make all
```

Reply (Y)es to any install questions if they appear.

This will:
- Install all build dependencies
- Download and extract VICE (and other supported emulators/utilities as available)
- Build and install VICE
- Set up a Samba share with subfolders for disks and roms
- Enable auto-login and auto-start of VICE (or other emulators)
- Hide the rainbow splash screen
- Install useful tools (Midnight Commander)

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
  Install Samba, create a share at `~/share` with `disks` and `roms` subfolders, and configure permissions.  
  Access from another computer using:  
  `smb://<your-pi-ip-address>/8bitpc`

- `make autologin_pi`  
  Enable auto-login for the current user (requires Raspberry Pi OS Desktop with LightDM).

- `make autostart_x64sc`  
  Add a command to your `~/.bash_profile` so that `x64sc` launches automatically when you log in on the console (not via SSH).

- `make setup_vice_config`  
  Copy the provided `sdl-vicerc` file into `~/.config/vice/` to set up default VICE settings for your user.  
  This ensures VICE starts with your preferred configuration out of the box.

- `make tools`  
  Install useful tools for working on the Pi, starting with Midnight Commander (`mc`), a text-based file manager.  
  Run `mc` in the terminal to launch it.

- `make clean`  
  Remove all downloaded and built files.

## Notes

- The Samba share is created at `~/share` with `disks` and `roms` subfolders for easy file management.
- The `autostart_x64sc` target only affects local console logins, not SSH sessions.
- For headless (Lite) setups, the Makefile is designed to work without a desktop environment.
- If you want VICE to start automatically for all users or in other scenarios, consider using a systemd user service or customizing `/etc/profile`.
- The rainbow splash screen will be hidden on next boot after running `make add_config_txt_changes`.
- To run VICE manually from the console run `~/vice-3.9/bin/x64sc` or simply power cycle the Pi400/500.

---
