#!/bin/bash

cd build
wget -A rpm -m -np -p https://www.kraxel.org/repos/jenkins/
for f in `du -a | grep rpm | grep -v "src.rpm"`; do rpm2cpio.pl $f | cpio -idmv; done

mkdir ../bios/ovmf-x64
cp usr/share/edk2.git/ovmf-x64/* ../bios/ovmf-x64/
mkdir ../bios/seabios
cp usr/share/seabios.git/* ../bios/seabios/

