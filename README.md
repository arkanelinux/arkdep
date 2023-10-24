# arkdep
A toolkit for building, deploying and maintaining a btrfs-based multi-root system.

arkdep attempts to be as simple to use as possible and avoid unnecessary abstraction, if you know how to use GNU/Linux picking up arkdep should be painless for it maintains much of your old familiar workflow.

## Usage
### Rolling out arkdep on a new system

> **Note** arkdep has as of now only been tested on Arch Linux-based systems

arkdep can be easily rolled out and torn down again, it is non-invasive by design. So it _should_ be safe to just toy around with it on your system.

System requirements;
- `/` is partitioned with btrfs
- `/boot` mounted boot partition
- Systemd-boot bootloader is installed and configured as the primary bootloader
- dracut, wget and curl are installed

The following command will initialize arkdep, it will deploy a subvolume containing all arkdep related files excluding kernels and initramfs to `/arkdep`. Kernel and initramfs will instead be stored in `/boot/arkdep` upon generation.
```shell
sudo arkdep init
```

Once ardep is installed you should prepare the overlay located at `/arkdep/overlay`. The overlay is copied directory on to the root filesystem of a new deployment, create directories inside of it as-if it were a root filesystem. For example, `/arkdep/overlay/etc` will be your `/etc` folder.

You will most likely wish to add the following to the overlay;
- passwd, shadow, group, subgid and subuid files
- Optionally an fstab, locale.conf/locale.gen and custom dracut configuration

Here is a reference fstab file, take note of the `subvol` mount option;
```shell
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/           btrfs     	rw,relatime,ssd,discard=async,space_cache=v2,subvolid=5,subvol=/,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/root       btrfs     	rw,relatime,ssd,discard=async,space_cache=v2,subvol=arkdep/shared/root,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/home       btrfs     	rw,relatime,ssd,discard=async,space_cache=v2,subvol=arkdep/shared/home,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/var        btrfs     	rw,relatime,ssd,discard=async,space_cache=v2,subvol=arkdep/shared/var,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/arkdep     btrfs     	rw,relatime,ssd,discard=async,space_cache=v2,subvol=arkdep,compress=zstd	0 0
UUID=1223-2137      	                    /boot       vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
```

If you wish to use custom kernel parameters you can edit `/arkdep/templates/systemd-boot`

### Deploying an image
To deploy the latest available image from the default repository run the following command;
```shell
sudo arkdep deploy
```
It will check in with the server defined in `/arkdep/config` as `repo_url` and pull the latest image defined in `$repo_url/database`, see [Repository](#Repository) for additional information.

### Deploying a specified image version
A specific image version to pull and deploy can be parsed like so;
```shell
sudo arkdep deploy 00ce35074659538f946be77d9efaefc37725335689
```
Simply provide the basename of the image and it will attempt to find it in `/database`.

You do not have to provide the full basename, you can provide it with an impartial basename, the first hit will be pulled and deployed.
```shell
sudo arkdep deploy 00ce
```

## Packaging
### Custom configurations
#### Arch Linux-based
```text
arkdep-build.d
├── customlinux			# Directory carrying a custom name
|  ├── overlay			# (Optional) Root filesystem overlay directory, contents are copied to root
|  ├── base.list		# Plain text file containing list of packages installed by pacstrap
|  ├── package.list		# (Optional) Plain text file containing list of packages installed by pacman
|  ├── systemd.services		# (Optional) Plain text file containing list of systemd services to enable
|  ├── type         		# Plain text file, for configs of the Arch type should contain `archlinux`
```

### Building an image
Use the arkdep-build script to build your customlinux images.

```shell
sudo arkdep-build customlinux

# Or alternatively using a custom image name
sudo ARKDEP_CUSTOM_NAME='customlinux_v1.0' arkdep-build customlinux
```

Once done you can find compressed and uncompressed copies of your new image in the `target` directory.

arkdep will by default generate a psuedo-random hex string and use this as the name of your image. This behaviour can be overwritten by assigning a custom name to the `ARKDEP_CUSTOM_NAME` environment variable.

## Repository

### Example repository layout
This would be a suitable layout if `repo_url` in `/arkdep/config` is set to `https://repo.example.com/arkdep`.
```text
repo.example.com
├── arkdep
|  ├── list		                # Plain text file containing names of all available image types
|  ├── customlinux
|  |  ├── database		        # Plain text file containing : delimited lists of all available images `image_name:compression_method:sha1sum`
|  |  ├── customlinux_v1.0.tar.zst	# Compressed disk images
|  |  ├── customlinux_v2.0.tar.zst	# Compressed disk images
```

### Example repository configuration
The `list` file is in part optional, it not utilized during the deployment process but the user may use it in combination with the `arkdep list` command to request a list of all available images in the repository.
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
The image name is used to find the actual image, users can also manually refer to a version with `arkdep deploy customlinux customlinux_v1.0`

The compression method is flexible, any compression method tar can infer is supported. Some examples being `xz`, `gz` and `zst`.

The sha1sum is used to ensure the file was downloaded properly.

arkdep will assume the top most entry in the database is the latest one, when no image version is defined or `latest` is requested it will grab the top most entry.

