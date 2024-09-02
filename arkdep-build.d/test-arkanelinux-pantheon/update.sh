# We switched from using EFI vars to timestamped bootloader entries, ensure the old named var is no longer used
bootctl set-default ''
