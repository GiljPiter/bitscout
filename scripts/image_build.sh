#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

install_required_package squashfs-tools

statusprint "Making sure package cache and other fs are detached.."
chroot_unmount_fs "./build.$GLOBAL_BASEARCH/chroot"

statusprint "Compressing chroot.."
SQUASHFSIMG="./build.$GLOBAL_BASEARCH/image/casper/filesystem.squashfs"
if [ -f "$SQUASHFSIMG" ]
then
 sudo rm -f "$SQUASHFSIMG"
fi

printf $(sudo du -sx --block-size=1 "build.$GLOBAL_BASEARCH" | cut -f1) | sudo tee ./build.$GLOBAL_BASEARCH/image/casper/filesystem.size >/dev/null

statusprint "Making squashfs image.."
sudo mksquashfs ./build.$GLOBAL_BASEARCH/chroot "$SQUASHFSIMG" -e boot -wildcards -ef ./resources/squashfs/exclude.list 

statusprint "Calculating files MD5 for integrity control.."
cd ./build.$GLOBAL_BASEARCH/image && find . -type f -print0 | xargs -0 sudo md5sum | grep -v "\./md5sum.txt" > md5sum.txt
cd ../../

statusprint "Creating grub-powered image..."
install_required_package grub-common
install_required_package grub-pc-bin
install_required_package grub-efi-ia32-bin
install_required_package grub-efi-amd64-bin
install_required_package mtools
install_required_package xorriso

sudo grub-mkrescue --modules="part_gpt iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-20.04-$GLOBAL_BASEARCH.iso ./build.$GLOBAL_BASEARCH/image -- -as mkisofs -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot

exit 0;
