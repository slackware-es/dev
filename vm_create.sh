#!/bin/bash

set -e 
set -a

if [ -z "$1" ]; then
	echo Usage:
	echo   ${0} slackbios kvm 20G 2048 BIOS user img/slackware64-14.2-install-dvd.iso
	echo   ${0} slackuefi kvm 20G 2048 UEFI user img/slackware64-14.2-install-dvd.iso
	exit 0
fi

ROOT=`dirname $0`

cd ${ROOT}
ROOT=`pwd`

PARAMS=(NAME ACCEL DISK_SIZE MEM_SIZE BOOT_TYPE NET_TYPE INSTALL_IMAGE)

for i in "${PARAMS[@]}"; do
	if [ -z "$1" ]; then
		echo Please specify $i
		exit -1
	fi
	declare ${i}=$1; shift
done
KVM=""
if [ "$ACCEL" == "kvm" ]; then
	 # KVM="-enable-kvm -machine q35,accel=kvm -device intel-iommu -cpu host"
	 KVM="-enable-kvm -cpu host"
fi
 
BIOS="-bios ${ROOT}/bios/seabios/bios.bin"
if [ "${BOOT_TYPE}" == "UEFI" ]; then
	BIOS="-drive if=pflash,format=raw,readonly,file=../../bios/ovmf-x64/OVMF_CODE-pure-efi.fd -drive if=pflash,format=raw,file=../../bios/ovmf-x64/OVMF_VARS-pure-efi.fd"
fi

mkdir -p vm/${NAME}
# Create disk image
qemu-img create -f qcow2 vm/${NAME}/disk.img ${DISK_SIZE} 

# Generate run command
cat << EOF > vm/${NAME}/install.sh
#!/usr/bin/env bash

qemu-system-x86_64 ${KVM} ${BIOS} -m ${MEM_SIZE} -cdrom ${INSTALL_IMAGE} -hda disk.img -boot d -net nic -net ${NET_TYPE} -m ${MEM_SIZE} -rtc base=localtime -vga std

EOF

cat << EOF > vm/${NAME}/run.sh
#!/usr/bin/env bash

qemu-system-x86_64 ${KVM} ${BIOS} -m ${MEM_SIZE} -hda disk.img -boot c -net nic -net ${NET_TYPE} -m ${MEM_SIZE} -rtc base=localtime -vga std

EOF

