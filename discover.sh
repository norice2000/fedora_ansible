#!/usr/bin/env bash
# Discover current system setup for Ansible restoration

OUTPUT_DIR="my_setup"
mkdir -p "$OUTPUT_DIR"

echo "========================================="
echo "  Discovering Your Fedora System Setup"
echo "========================================="
echo

# 1. Hyper Terminal
echo "[1/9] Checking Hyper terminal..."
if command -v hyper &> /dev/null; then
    echo "  ✓ Hyper found"
    if [ -f ~/.hyper.js ]; then
        cp ~/.hyper.js "$OUTPUT_DIR/hyper.js"
        echo "  ✓ Config backed up"
    fi
else
    echo "  ✗ Hyper not installed"
fi
echo

# 2. GNOME Extensions
echo "[2/9] Collecting GNOME extensions..."
if command -v gnome-extensions &> /dev/null; then
    gnome-extensions list > "$OUTPUT_DIR/gnome_extensions.txt"
    gnome-extensions list --enabled > "$OUTPUT_DIR/gnome_extensions_enabled.txt"
    dconf dump /org/gnome/shell/extensions/ > "$OUTPUT_DIR/gnome_extensions_settings.dconf"
    dconf dump /org/gnome/desktop/ > "$OUTPUT_DIR/gnome_desktop_settings.dconf"
    echo "  ✓ Extensions and settings backed up"
else
    echo "  ✗ GNOME extensions not found"
fi
echo

# 3. NFS mounts
echo "[3/9] Checking NFS mounts..."
if grep -q nfs /etc/fstab 2>/dev/null; then
    grep nfs /etc/fstab > "$OUTPUT_DIR/nfs_mounts.txt"
    echo "  ✓ NFS mounts backed up"
else
    echo "No NFS mounts" > "$OUTPUT_DIR/nfs_mounts.txt"
    echo "  - No NFS mounts found"
fi
echo

# 4. pip3 packages
echo "[4/9] Collecting pip3 packages..."
if command -v pip3 &> /dev/null; then
    pip3 list --format=freeze > "$OUTPUT_DIR/pip3_packages.txt"
    PACKAGE_COUNT=$(wc -l < "$OUTPUT_DIR/pip3_packages.txt")
    echo "  ✓ $PACKAGE_COUNT packages backed up"
else
    echo "  ✗ pip3 not installed"
fi
echo

# 5. KVM/QEMU setup
echo "[5/9] Checking KVM/QEMU..."
if command -v virsh &> /dev/null; then
    rpm -qa | grep -E 'qemu|libvirt|virt-' > "$OUTPUT_DIR/kvm_packages.txt"
    groups > "$OUTPUT_DIR/user_groups.txt"
    sudo virsh net-dumpxml default > "$OUTPUT_DIR/libvirt_default_network.xml" 2>/dev/null || \
        echo "<network/>" > "$OUTPUT_DIR/libvirt_default_network.xml"
    echo "  ✓ KVM info backed up"
else
    echo "  ✗ KVM not installed"
fi
echo

# 6. Network interface
echo "[6/9] Detecting network interface..."
INTERFACE=$(ip route show default | grep -oP 'dev \K\w+' | head -1)
echo "INTERFACE=$INTERFACE" > "$OUTPUT_DIR/network_interface.txt"
echo "  ✓ Interface: $INTERFACE"
echo

# 7. iptables rules
echo "[7/9] Backing up iptables rules..."
sudo iptables-save > "$OUTPUT_DIR/iptables_current.rules"
sudo iptables -t nat -L POSTROUTING -n -v | grep 192.168.122 > "$OUTPUT_DIR/iptables_kvm_nat.txt" 2>/dev/null || \
    echo "No KVM NAT rules" > "$OUTPUT_DIR/iptables_kvm_nat.txt"
sudo iptables -L FORWARD -n -v | grep 192.168.122 > "$OUTPUT_DIR/iptables_kvm_forward.txt" 2>/dev/null || \
    echo "No KVM FORWARD rules" > "$OUTPUT_DIR/iptables_kvm_forward.txt"
echo "  ✓ iptables rules backed up"
echo

# 8. libvirt hooks
echo "[8/9] Checking libvirt hooks..."
if [ -f /etc/libvirt/hooks/network ]; then
    sudo cp /etc/libvirt/hooks/network "$OUTPUT_DIR/libvirt_network_hook.sh"
    echo "  ✓ Network hook backed up"
else
    echo "  - No network hook found"
fi
echo

# 9. System services
echo "[9/9] Checking services..."
systemctl is-enabled firewalld > "$OUTPUT_DIR/firewalld_status.txt" 2>&1
systemctl is-enabled libvirtd > "$OUTPUT_DIR/libvirtd_status.txt" 2>&1
echo "  ✓ Service status saved"
echo

echo "========================================="
echo "  Discovery Complete!"
echo "========================================="
echo
echo "Backup saved in: $OUTPUT_DIR/"
echo
echo "Files created:"
ls -1 "$OUTPUT_DIR/" | sed 's/^/  - /'
echo
echo "Next steps:"
echo "  1. Review the backed up files"
echo "  2. Copy entire directory to safe location"
echo "  3. After fresh install, copy back and run:"
echo "     ansible-playbook site.yml"