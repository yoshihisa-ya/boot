#!/usr/bin/env bash
set -euo pipefail

MEM=${MEM:-2048}
CPU=${CPU:-2}
DISK_SIZE=${DISK_SIZE:-8G}
BRIDGE=${BRIDGE:-br0}
TAP=${TAP:-tap-$$}

# ブリッジ存在チェック
if ! ip link show "$BRIDGE" >/dev/null 2>&1; then
    echo "Error: bridge '$BRIDGE' が見つかりません。" >&2
    exit 1
fi

# クリーンアップ関数
cleanup() {
    sleep 1
    rm -rf -- "$DISK"
    if ip link show "$TAP" >/dev/null 2>&1; then
        sudo ip link set "$TAP" down >/dev/null 2>&1 || true
        sudo ip link delete "$TAP" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# /tmp/qemu-XXXXXX.qcow2 を作成
DISK=$(mktemp /tmp/qemu-XXXXXX.qcow2)
qemu-img create -f qcow2 "$DISK" "$DISK_SIZE" >/dev/null

# TAP インタフェースをブリッジに接続
sudo ip tuntap add dev "$TAP" mode tap
sudo ip link set "$TAP" master "$BRIDGE"
sudo ip link set "$TAP" up

# PXE で起動するため -boot n を指定（ネットワークブート）
# UEFI, KVM, VirtIO
qemu-system-x86_64 \
    -m "$MEM" -smp "$CPU" \
    -drive file="$DISK",if=virtio,format=qcow2,cache=writeback \
    -netdev tap,id=net0,ifname="$TAP",script=no,downscript=no \
    -device virtio-net-pci,netdev=net0 \
    -boot n \
    -bios "/usr/share/OVMF/OVMF_CODE.fd" \
    -enable-kvm
