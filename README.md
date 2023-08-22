# Arkanium
A toolkit for building, deploying and maintaining a btrfs-based multi-root system.

## Packaging
### Custom configurations
#### Arch Linux-based
```text
arkanium-build.d
├── customlinux			# Directory carrying a custom name
|  ├── overlay			# (Optional) Root filesystem overlay directory, contents are copied to root
|  ├── base.list		# Plain text file containing list of packages installed by pacstrap
|  ├── package.list		# (Optional) Plain text file containing list of packages installed by pacman
|  ├── systemd.services		# (Optional) Plain text file containing list of systemd services to enable
|  ├── type         		# Plain text file, for configs of the Arch type should contain `archlinux`
```

### Building an image
Use the arkanium-build script to build your customlinux images.

```shell
sudo arkanium-build customlinux

# Or alternatively using a custom image name
sudo ARKANIUM_OVERWRITE_RANDOM='customlinux_v1.0' arkanium-build customlinux
```

Once done you can find compressed and uncompressed copies of your new image in the `target` directory.

Arkanium will by default generate a psuedo-random hex string and use this as the name of your image. This behaviour can be overwritten by assigning a custom name to the `ARKANIUM_OVERWRITE_RANDOM` environment variable.

## Repository

### Example repository layout
This would be a suitable layout if `repo_url` in `/arkanium/config` is set to `https://repo.example.com/arkanium`.
```text
repo.example.com
├── arkanium
|  ├── list		                # Plain text file containing names of all available image types
|  ├── customlinux
|  |  ├── database		        # Plain text file containing : delimited lists of all available images `image_name:compression_method:sha1sum`
|  |  ├── customlinux_v1.0.tar.zst	# Compressed disk images
|  |  ├── customlinux_v2.0.tar.zst	# Compressed disk images
```

### Example repository configuration
The `list` file is in part optional, it not utilized during the deployment process but the user may use it in combination with the `arkanium-deploy list` command to request a list of all available images in the repository.
```text
customlinux
customlinux-gnome
customlinux-kde
```

The `database` file contains a `:` delimited list of all available images. Each line contains the following information `image_name:compression_method:sha1sum`.
```text
customlinux_v2.0:zst:d5f45b2dac77399b37231c6ec4e864d184d35cf1
customlinux_v1.0:zst:80ba4c7f3ff7a0ebce8e67d5b73f87c56af1b9f3
```
The image name is used to find the actual image, users can also manually refer to a version with `arkanium-deploy deploy customlinux customlinux_v1.0`

The compression method is flexible, any compression method tar can ifner is supported. Some examples being `xz`, `gz` and `zst`.

The sha1sum is used to ensure the file was downloaded properly.

Arkanium will assume the top most entry in the database is the latest one, when no image version is defined or `latest` is requested it will grab the top most entry.
