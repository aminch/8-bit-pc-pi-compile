# VICE Pi Compile Makefile

This Makefile automates downloading, building, and installing the VICE emulator on a Linux system, such as a Raspberry Pi, using the SDL2 library provided by your system's package manager.

## Prerequisites

- A Debian-based Linux system (e.g., Raspberry Pi OS, Ubuntu)
- `sudo` privileges for installing system packages
- Internet connection for downloading sources

## Usage

Open a terminal in this directory and run:

```bash
make
```

This will execute all steps: install dependencies, download and extract VICE, prepare the build system, configure, build, and install VICE.

### Available Targets

- `make deps`  
  Install all required system packages for building VICE, including SDL2 from your package manager.

- `make download`  
  Download the VICE source tarball.

- `make extract`  
  Extract the downloaded VICE source.

- `make autogen`  
  Run the VICE autogen script (prepares the build system).

- `make configure`  
  Configure the VICE build, using the system-provided SDL2.

- `make build`  
  Build VICE using all available CPU cores.

- `make install`  
  Install VICE to your home directory.

- `make clean`  
  Remove all downloaded and built files (resets the build environment).

## Customization

You can edit the Makefile to change installation directories or VICE version by modifying the variables at the top of the file.

## Notes

- The Makefile installs VICE into your home directory by default.
- SDL2 is now provided by your system's package manager (`libsdl2-dev`), so there is no need to build SDL2 from source.
- If you encounter errors about missing separators, ensure all command lines in the Makefile are indented with tabs, not spaces.

---
