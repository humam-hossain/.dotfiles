# Arch Linux Setup

- Arch Installation Documentation: https://wiki.archlinux.org/title/Installation_guide

## Necessary Software Install

```bash
sudo pacman -Syu base-devel nano networkmanager intel-ucode sof-firmware efibootmgr man-db man-pages openssh wpa_supplicant
```

### Create user

- Add user

```bash
useradd -m -G wheel -s/bin/bash pera
```

- Set user password

```bash
passwd pera
```

- Give sudo access to user

```bash
EDITOR=nano visudo

# uncomment
# %wheel ALL=(ALL:ALL) ALL
```

### Bootloader

- add the systemd boot manager to the ESP

```bash
bootctl install
```

- Explanation
    - Copies `systemd-bootx64.efi` into `/boot/EFI/systemd/`.
    - Creates a minimal `/boot/loader/loader.conf` if it didn’t exist.
    - Creates a sample entry `/boot/loader/entries/linux.conf`.
    

```bash
tree /boot/

/boot/
├── EFI
│   ├── BOOT
│   │   └── BOOTX64.EFI
│   ├── Linux
│   └── systemd
│       └── systemd-bootx64.efi
├── initramfs-linux-fallback.img
├── initramfs-linux.img
├── intel-ucode.img
├── loader
│   ├── entries
│   │   └── arch.conf
│   ├── entries.srel
│   ├── keys
│   ├── loader.conf
│   └── random-seed
└── vmlinuz-linux

8 directories, 10 files
```

- Configuring the loader.conf

```bash
#timeout 3
#console-mode keep

default		    arch
timeout		    10
console-mode	max
editor		    no
```

- Explanation
    - **default**
        - Matches the filename (minus `.conf`) in `/boot/loader/entries/`.
        - Here, it boots the entry file `arch.conf`.
    - **timeout**
        - Seconds to wait before auto-booting the default.
        - Set to `0` for immediate boot, or a higher value if you want more menu time.
    - **console-mode**
        - Sets text resolution. `max` uses your firmware’s highest. You can also specify dimensions like `80x25`.
- Create `/boot/loader/entries/arch.conf` with these fields:
    
    ```bash
    title	    Arch Linux
    linux	    /vmlinuz-linux
    initrd	  /initramfs-linux.img
    options	  root=UUID=3778e853-d3a4-4aba-bf4d-0fe163d2f2d3 rw
    ```
    
    - get UUID
    
    ```bash
    blkid -s UUID -o value /dev/nvme1n1p >> /boot/loader/entries/arch.conf
    ```
    
- Explanation
    - **title**
        - The label shown in the menu.
    - **linux**
        - Path to your kernel image. Under Arch’s default layout it’s `/vmlinuz-linux` (symlink managed by `mkinitcpio`).
    - **initrd**
        - Path to your initial ramdisk (`initramfs`) image from `mkinitcpio`, needed to load modules (filesystems, encryption, LVM).
    - **options**
        - Kernel command line.
            - `root=UUID=…` tells the kernel which partition to mount as `/`.
            - `rw` mounts it read-write.
- EFI boot entry
    - list entries
        
        ```bash
        efibootmgr -v
        ```
        
    - delete entry
        
        ```bash
        efibootmgr -b 0004 -B
        ```
        
    - rearrange boot order
        
        ```bash
        efibootmgr --bootorder 0001,0002
        ```
        
- exit the chroot, unmount and reboot

```bash
exit
unmount -R /mnt
reboot
```