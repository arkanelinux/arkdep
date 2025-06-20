#!/usr/bin/env bash

# Install base-devel for AUR building capabilities
arch-chroot $workdir pacman -S --noconfirm base-devel git

# Create build user for AUR packages
arch-chroot $workdir useradd -m aur_builder
arch-chroot $workdir bash -c 'echo "aur_builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/aur_builder'

# Install yay AUR helper
arch-chroot $workdir bash -c 'cd /tmp && \
    sudo -u aur_builder git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    sudo -u aur_builder makepkg -si --noconfirm'
