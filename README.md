# boot
iPXE scripts for home lab

## iPXE
```
apt install build-essential
apt build-dep ipxe

mkdir /srv/tftp

git clone https://github.com/ipxe/ipxe.git
cd ipxe

cat >src/config/local/general.h <<'EOF'
#define CERT_CMD
#define DOWNLOAD_PROTO_HTTPS
#define IMAGE_TRUST_CMD
EOF

make -j $(($(getconf _NPROCESSORS_ONLN) + 2)) -C src bin/undionly.kpxe bin-x86_64-efi/ipxe.efi
cp src/bin/undionly.kpxe src/bin-x86_64-efi/ipxe.efi ../
```


## dnsmasq
```
apt install dnsmasq
```

### /etc/dnsmasq.conf
```
dhcp-boot=undionly.kpxe
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-boot=tag:efi-x86_64,ipxe.efi
dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
dhcp-boot=tag:ipxe,https://boot.yoshihisa.link/boot.ipxe
enable-tftp
tftp-root=/srv/tftp
```
