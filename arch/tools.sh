#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] CLI Utilities & Basic Tools"
pacman_pkgs_0=(
  unzip         # For extracting and viewing files in .zip archives
  tar           # Utility used to store, backup, and transport files
  curl          # command line tool and library for transferring data with URLs
  wget          # Network utility to retrieve files from the web
  fastfetch     # A feature-rich and performance oriented neofetch like system information tool
  dysk          # Get information on your mounted filesystems
  pastel        # A command-line tool to generate, analyze, convert and manipulate colors
  wikiman       # Offline search engine for manual pages, Arch Wiki, Gentoo Wiki and other documentation
  tree          # A directory listing program displaying a depth indented list of files
  ripgrep       # A search tool that combines the usability of ag with the raw speed of grep
  jq            # Command-line JSON processor
  speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
  termdown      # Countdown timer and stopwatch in your terminal
  expac         # alpm data (pacman database) extraction utility
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_0[@]}"

yay_pkgs_0=(
  durdraw   # Frame based ASCII and ANSI drawing and playback program
  cbonsai   # A bonsai tree generator, written in C using ncurses
  pacfinder # Pacman repository & package explorer for Arch Linux.
)
yay -Sy --noconfirm --needed "${yay_pkgs_0[@]}"

echo "[INSTALL] Development, Git & Docker"
pacman_pkgs_1=(
  micro            # Modern and intuitive terminal-based text editor
  lazygit          # Simple terminal UI for git commands
  github-cli       # The GitHub CLI
  gitlogue         # A cinematic Git commit replay tool for the terminal
  tig              # Text-mode interface for Git.
  serie            # A rich git commit graph in your terminal
  autoconf-archive # A collection of freely re-usable Autoconf macros
  cmake            # A cross-platform open-source make system
  go               # Core compiler tools for the Go programming language
  gradle           # Powerful build system for the JVM
  jdk8-openjdk     # OpenJDK Java 8 development kit
  docker           # Pack, ship and run any application as a lightweight container
  docker-buildx    # Docker CLI plugin for extended build capabilities with BuildKit
  docker-compose   # Fast, isolated development environments using Docker
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_1[@]}"

yay_pkgs_1=(
  oxker   # A simple TUI to view & control Docker containers
  posting # The modern API client that lives in your terminal
)
yay -Sy --noconfirm --needed "${yay_pkgs_1[@]}"

echo "[INSTALL] Internet, Network & Remote Access"
pacman_pkgs_2=(
  w3m                 # Text-based Web browser as well as pager
  qutebrowser         # A keyboard-driven, vim-like browser based on Python and Qt
  torbrowser-launcher # Securely and easily download, verify, install, and launch Tor Browser in Linux
  wireshark-qt        # Network traffic and protocol analyzer/sniffer - Qt GUI
  mitmproxy           # SSL-capable man-in-the-middle HTTP proxy
  qbittorrent         # An advanced BitTorrent client programmed in C++, based on Qt toolkit and libtorrent-rasterbar
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_2[@]}"

yay_pkgs_2=(
  discord               # All-in-one voice and text chat for gamers
  zoom                  # Video Conferencing and Web Conferencing Service
  teams-for-linux       # Unofficial Microsoft Teams client for Linux using Electron.
  teamspeak             # Software for quality voice communication via the Internet
  brave-bin             # Web browser that blocks ads and trackers by default (binary release)
  librewolf-bin         # Community-maintained fork of Firefox, focused on privacy, security and freedom.
  anydesk-bin           # The Fast Remote Desktop Application
  rustdesk-bin          # Yet another remote desktop software, written in Rust. Works out of the box, no configuration required.
  hide-client           # Hide.me CLI VPN client for Linux
  windscribe-cli-v2-bin # Windscribe CLI tool for Linux
  localsend             # An open source cross-platform alternative to AirDrop
  freedownloadmanager   # FDM is a powerful modern download accelerator and organizer.
)
yay -Sy --noconfirm --needed "${yay_pkgs_2[@]}"

echo "[INSTALL] Media, Graphics & Video"
pacman_pkgs_3=(
  viu      # Simple terminal image viewer
  vlc      # Free and open source cross-platform multimedia player and framework
  feh      # Fast and light imlib2-based image viewer
  f3d      # A fast and minimalist 3D viewer
  gimp     # GNU Image Manipulation Program
  inkscape # Professional vector graphics editor
  kdenlive # A non-linear video editor for Linux using the MLT video framework
  mpv      # a free, open source, and cross-platform media player
  scrcpy   # Display and control your Android device
  yt-dlp   # A youtube-dl fork with additional features and fixes
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_3[@]}"

yay_pkgs_3=(
  webcamize # Use (almost) any camera as a webcam
  qview     # qView is a Qt image viewer designed with minimalism and usability in mind.
)
yay -Sy --noconfirm --needed "${yay_pkgs_3[@]}"

echo "[INSTALL] Productivity, Documents & Knowledge"
pacman_pkgs_4=(
  libreoffice-fresh   # LibreOffice branch which contains new features and program enhancements
  task                # Taskwarrior, a command-line todo list manager
  qpdf                # QPDF: A Content-Preserving PDF Transformation System
  zathura             # Minimalistic document viewer
  zathura-pdf-poppler # Adds pdf support to zathura by using the poppler engine
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_4[@]}"

yay_pkgs_4=(
  affine-bin # There can be more than Notion and Miro.AFFiNE is a next-gen knowledge base that brings planning, sorting and creating all together. Privacy first, open-source, customizable and ready to use.(Prebuilt version.Use system-wide electron)
  sc-im      # A ncurses vim-like terminal spreadsheet program, based on SC
  zotero     # A free, easy-to-use tool to help you collect, organize, cite, and share your research sources.
)
yay -Sy --noconfirm --needed "${yay_pkgs_4[@]}"

echo "[INSTALL] System, Disks, Gaming & Misc"
pacman_pkgs_5=(
  smartmontools # Control and monitor S.M.A.R.T. enabled ATA and SCSI Hard Drives
  caligula      # A user-friendly, lightweight TUI for disk imaging
  memtester     # A userspace utility for testing the memory subsystem for faults
  distrobox     # Use any linux distribution inside your terminal.
  seahorse      # GNOME application for managing PGP keys
  lutris        # Open Gaming Platform
  wine-staging  # A compatibility layer for running Windows programs - Staging branch
  winetricks    # Script to install various redistributable runtime libraries in Wine.
  gnuplot       # Plotting package which outputs to X11, PostScript, PNG, GIF, and others
  graphviz      # Graph visualization software
  gource        # software version control visualization
)
sudo pacman -Sy --noconfirm --needed "${pacman_pkgs_5[@]}"

yay_pkgs_5=(
  lmstudio-bin # LM Studio - A desktop app for exploring and running large language models locally
)
yay -Sy --noconfirm --needed "${yay_pkgs_5[@]}"
