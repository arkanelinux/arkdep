# Arkdep
Toolkit for building, deploying and maintaining an immutable, btrfs-based, multi-root system.

Arkdep attempts to be as simple to use as possible and avoid unnecessary abstraction, if you know how to use GNU/Linux picking up Arkdep should be painless for it maintains much of your old familiar workflow.

> [!WARNING]
> Arkdep is still in active development, no more breaking changes are planned since all core functionality is now in, however the current codebase has yet to be thoroughly tested, there may be lingering bugs or other issues

## Usage
### Rolling out Arkdep on a new system
> [!WARNING]
> Arkdep has as of now only been tested on Arch Linux-based systems

> [!NOTE]
> If you are only intend on building images Arkdep does not have to be initted on the system

Arkdep can be easily rolled out and torn down again, it is non-invasive by design. So it _should_ be safe to just toy around with it on your system.

System requirements for usage;
- `/` is partitioned with btrfs
- `/boot` mounted boot partition
- 512MiB boot partition for max 2 deployments, 1GiB recommended
- Systemd-boot bootloader is installed and configured as the primary bootloader
- `dracut`, `wget`, `curl` and `btrfs-progs` are installed

System requirements for image building;
- `arch-install-scripts` and `btrfs-progs` are installed
- A btrfs partitioned workdir, default is `/var/tmp`

The following command will initialize Arkdep, it will deploy a subvolume containing all Arkdep related files excluding kernels and initramfs to `/arkdep`. Kernel and initramfs will instead be stored in `/boot/arkdep` upon generation.
```shell
sudo arkdep init

# Alternatively to init in to a specific directory
sudo ARKDEP_ROOT=/target/dir arkdep init
```

Once ardep is installed you should prepare the overlay located at `/arkdep/overlay`. The overlay is copied directly on to the root filesystem of a new deployment, create directories inside of it as-if it were a root filesystem. For example, `/arkdep/overlay/etc` will be your `/etc` folder.

You will most likely wish to add the following to the overlay;
- passwd, shadow, group, subgid and subuid files containing only entries for root and normal user accounts, system accounts will be supplied via the images and are stored separate in `/usr/lib`.
- fstab file with at least a writable `/var` subvolume configured
- Optionally a locale.conf/locale.gen, localtime symlink and custom dracut configuration

Here is a reference fstab file, take note of the `subvol` mount option;
```shell
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/home       btrfs     	rw,relatime,discard=async,space_cache=v2,subvol=arkdep/shared/home,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/var        btrfs     	rw,relatime,discard=async,space_cache=v2,subvol=arkdep/shared/var,compress=zstd	0 0
UUID=f8b62c6c-fba0-41e5-b12c-42aa1cdaa452	/arkdep     btrfs     	rw,relatime,discard=async,space_cache=v2,subvol=arkdep,compress=zstd	0 0
UUID=1223-2137                              /boot       vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
```

If you wish to use custom kernel parameters you can edit `/arkdep/templates/systemd-boot`

### Deploying an image
To deploy the latest available image from the default repository run the following command;
```shell
sudo arkdep deploy
```
It will check in with the server defined in `/arkdep/config` as `repo_url` and pull the latest image defined in `$repo_url/$repo_default_image/database`, see [Repository](#Repository) for additional information.

### Deploying a specified image version
A specific image version to pull and deploy can be parsed like so;
```shell
sudo arkdep deploy arkanelinux 00ce35074659538f946be77d9efaefc37725335689
```

The target name may be substituted with a `-` to pull the default target.
```shell
sudo arkdep deploy - 00ce35074659538f946be77d9efaefc37725335689
```

An item may be installed directly from the local `/arkdep/cache` directory, this will skip the database download and checksum check.
```shell
sudo arkdep deploy cache 00ce35074659538f946be77d9efaefc37725335689
```

You do not have to provide the full image name, you can provide it with an impartial image name, the first hit will be pulled and deployed.
```shell
sudo arkdep deploy arkanelinux 00ce
```

## Packaging
### Custom configurations
#### Arch Linux-based
```text
arkdep-build.d
├── customlinux			# Directory carrying a custom name
|  ├── overlay			# (Optional) Root filesystem overlay directory, contents are copied to root
|  ├── boostrap.list		# Plain text file containing list of packages installed by pacstrap, used for installing the base system
|  ├── package.list		# (Optional) Plain text file containing list of packages installed by pacman in a chroot, used for aditional package installations
|  ├── type         		# Plain text file, for configs of the Arch type should contain `archlinux`
|  ├── extensions		# (Optional) Directory for custom scripts
|     ├── post-bootstrap.sh	# (Optional) Custom bash script which runs after bootstrapping the system
|     ├── post-install.sh	# (Optional) Custom bash script which runs after system installation is finished
```

### Building an image
> [!NOTE]
>  If you are planning to spin custom images you will need to implement some type of mechanism for loading the `/usr/lib` account and group files, Arkane uses a patched [libnss-extrausers](https://github.com/arkanelinux/libnss-extrausers) PAM module to achieve this, Fedora Silverblue uses sssd

Use the arkdep-build script to build your customlinux images, currently the script is assuming to be run from inside of arkdep-build.d's parent directory.

```shell
sudo arkdep-build customlinux

# Or alternatively using a custom image name
sudo ARKDEP_CUSTOM_NAME='customlinux_v1.0' arkdep-build customlinux
```

Once done you can find compressed and uncompressed copies of your new image in the `target` directory.

Arkdep will by default generate a psuedo-random hex string and use this as the name of your image. This behaviour can be overwritten by assigning a custom name to the `ARKDEP_CUSTOM_NAME` environment variable.

## Repository

### Example repository layout
This would be a suitable layout if `repo_url` in `/arkdep/config` is set to `https://repo.example.com/arkdep`.
```text
repo.example.com
├── arkdep
|  ├── list		                # Plain text file containing names of all available image types
|  ├── customlinux
|  |  ├── database		        # Plain text file containing : delimited lists of all available images `image_name:compression_method:sha_sum`
|  |  ├── customlinux_v1.0.tar.zst	# Compressed disk images
|  |  ├── customlinux_v1.0.tar.zst.sig	# Detached GPG signature
|  |  ├── customlinux_v2.0.tar.zst	# Compressed disk images
|  |  ├── customlinux_v2.0.tar.zst.sig	# Detached GPG signature
|  ├── customlinux-gnome
|  |  ├── database
|  |  ├── customlinux-gnome_v1.0.tar.zst
|  |  ├── customlinux-gnome_v2.0.tar.zst
```

### Example repository configuration
The `list` file is in part optional, it not utilized during the deployment process but the user may use it in combination with the `arkdep get-available` command to request a list of all available images in the repository.
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

The SHA checksum is used to ensure the file was downloaded properly. sha1, sha224, sha256, sha384 and sha512 are all supported.

Arkdep will assume the top most entry in the database is the latest one, when no image version is defined or `latest` is requested it will grab the top most entry.

### Signed images
A GPG signature is by default optional, if available Arkdep will use it instead of the sha1sum to verify image integrity. Arkdep can be configured to require these files to be provided by setting `gpg_signature_check` to `2` in the config file.

A keyring with trusted (private) keys is stored at `/arkdep/keys/trusted-keys`, keys are only accepted in binary format.

Keys can be exported and added to the keyring like so, this process can be repeated to add multiple keys;
```shell
gpg --output example.gpg --export example@example.com

cat example.gpg | sudo tee -a /arkdep/keys/trusted-keys
```

Arkdep assumes the signatures to be identical in name to their parent file with a .sig appended.

Generate a signature like so;
```shell
gpg --output customlinux_v1.0.tar.zst.sig --detach-sig customlinux_v1.0.tar.zst
```

Then simply drop these signatures next to disk image itself.
