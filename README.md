# Arkanium
A toolkit for building, deploying and maintaining a btrfs-based multi-root system.

## Packaging
### Custom configurations
#### Arch Linux-based
```text
arkanium-build.d
├── customlinux				# Directory carrying a custom name
|  ├── overlay				# Root filesystem overlay directory, contents are copied to root
|  ├── base.list			# Plain text file containing list of packages installed by pacstrap
|  ├── package.list			# (Optional) Plain text file containing list of packages installed by pacman
|  ├── systemd.services		# (Optional) Plain text file containing list of systemd services to enable
|  ├── type         		# Plain text file, for configs of the Arch type should contain `archlinux`
```

### Building an image
Use the arkanium-build script to build your customlinux images.

```shell
$	sudo arkanium-build customlinux
```

Once done you can find compressed and uncompressed copies of your new image in the `target` directory.

Arkanium will by default generate a psuedo-random hex string and use this as the name of your image. This behaviour can be overwritten by assigning a custom name to the `ARKANIUM_OVERWRITE_RANDOM` environment variable.