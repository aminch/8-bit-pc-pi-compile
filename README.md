# 8-bit PC Pi Compile

This project **8-bit PC Pi Compile** is a Makefile to enable the installation of Vice the Commodore 64 emulator and Atari800 the Atari 8-bit PC emulator on Raspberry Pi OS Lite (64-bit). 

In addition it installs a `menu` that allow easy switching of the default emulator, and easy configuration the main features of the emulators and Pi OS Lite.

The goal of the project is to try and keep the feel of these old 8-bit computers by stripping back everything from the OS (hence the use of Pi OS Lite) and booting directly into the emulator.

## Hardware

This project was designed for one of two hardware setups, but given it's based on PiOS Lite (64-bit) it will run on any Raspberry Pi 4 or 5. 

### Setup #1

Modern hardware with an adapter to run original joysticks.

 * Pi 500 (recommended) or Pi 400
 * [BMC Joystick Adapter](https://github.com/aminch/bmc-joy-pcb)
 * [Raspberry Pi 27W USB-C Power Supply](https://www.raspberrypi.com/products/27w-power-supply/)

### Setup #2

Complete old school look and feel with original C64 case and keyboard.  

 * Pi 5 (recommended) or Pi 4B
 * [BMC PCB](https://github.com/aminch/bmc-pcb) (at least v 2.0.5)
 * Original C64 case (C64C or breadbin)
 * Original C64 keyboard (or new equivalent)
 * [Raspberry Pi 27W USB-C Power Supply](https://www.raspberrypi.com/products/27w-power-supply/)

 **Note:** You CANNOT run [BMC64](https://accentual.com/bmc64/), on a Pi 4B or Pi 5. To run BMC64 you need to use a Pi 3B+, which will also work in the above old school hardware.

## Software

By using this Makefile both the Vice C64 and Atari800 emulators will be installed and automatically configured to support both of the hardware setups listed above.

### Creating Pi OS Lite Installation

First you need to get a fresh MicroSD card and set it up with an installation of Pi OS Lite (64-bit)

1. **Download and Install Raspberry Pi Imager**  
   Get it from [Raspberry Pi Imager](https://www.raspberrypi.com/software/).

2. **Write the Raspberry Pi OS Lite (64-bit) image to a MicroSD Card**  
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

### First Boot: Installation of Emulators

Steps to install the emulators, patches and configuration files.

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
4. **Build and install everything**
    ```bash
    make all
    ```

If everything went well you will be presented with a message saying that the installation is complete and you need to reboot to finalise the setup.

## 8-bit PC Menu and Usage

### What the Makefile Installs and Sets Up

After installation the following components are installed and configured:

- **VICE (Commodore 64 Emulator):** Downloaded, built, and installed with default configuration for Pi hardware.
- **Atari800 (Atari 8-bit Emulator):** Downloaded, built, and installed with default configuration for Pi hardware.
- **8-bit PC Menu System:** A simple shell `menu` is installed to allow easy switching between emulators and configuration options, makes it easier that from within the emulators themselves. 
- **Samba File Sharing:** A share is created at `~/share` with `disks` and `roms` subfolders for easy file management from other computers.
- **Auto-login and Auto-start:** The system is configured to auto-login and auto-start the selected emulator on boot.
- **Useful Tools:** Midnight Commander (`mc`) and other utilities are installed for file management and system maintenance.

### What Can Be Changed in the "menu" Install

The installed menu system is launched with the `menu`  command and provides options to:

- **Switch Default Emulator:** Choose between VICE (C64) and Atari800 as the default emulator to launch on boot.
- **Configure Emulator Settings:** Adjust key mappings, joystick settings, display options, and other emulator-specific features.
- **System Settings:** Change WiFi configuration, hostname, and other Pi OS Lite settings using the official raspi-config script.
- **Updates:** Update the menu script or Pi OS Lite itself.
- **Reboot or Shutdown:** Easily reboot or power off the system from the menu.

The menu is designed to be simple and accessible from the console, making it easy to customize your 8-bit PC experience without needing to edit configuration files manually.

#### WiFi

WiFi should have been configured in Raspberry Pi Imager but if you need to change anything you can launch raspi-config from the `menu`.

From the raspi-config menu, select "System Options" > "Wireless LAN" to set or update your WiFi details. This is the recommended way to troubleshoot or change network settings on Pi OS Lite.

---
