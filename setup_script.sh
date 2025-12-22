#!/usr/bin/env bash
# Discover current system setup for Ansible playbook

OUTPUT_DIR="my_setup"
mkdir -p "$OUTPUT_DIR"

echo "=== Discovering Your System Setup ==="

# 1. Hyper Terminal
echo "1. Checking for Hyper terminal..."
if command -v hyper &> /dev/null; then
    echo "Hyper found"
    if [ -f ~/.hyper.js ]; then
        cp ~/.hyper.js "$OUTPUT_DIR/hyper.js"
        echo "Hyper config backed up"
    fi
else
    echo "Hyper not found"
fi

# 2. GNOME Extensions
echo "2. Collecting GNOME extensions..."
if command -v gnome-extensions &> /dev/null; then
    gnome-extensions list > "$OUTPUT_DIR/gnome_extensions.txt"
    # Get enabled extensions
    gnome-extensions list --enabled > "$OUTPUT_DIR/gnome_extensions_enabled.txt"
    
    # Backup GNOME settings
    dconf dump /org/gnome/shell/extensions/ > "$OUTPUT_DIR/gnome_extensions_settings.dconf"
    dconf dump /org/gnome/desktop/ > "$OUTPUT_DIR/gnome_desktop_settings.dconf"
    echo "GNOME extensions and settings backed up"
fi

# 3. NFS mounts
echo "3. Checking NFS mounts..."
grep nfs /etc/fstab > "$OUTPUT_DIR/nfs_mounts.txt" 2>/dev/null || echo "No NFS mounts" > "$OUTPUT_DIR/nfs_mounts.txt"
cat "$OUTPUT_DIR/nfs_mounts.txt"

# 4. pip3 packages
echo "4. Collecting pip3 packages..."
if command -v pip3 &> /dev/null; then
    pip3 list --format=freeze > "$OUTPUT_DIR/pip3_packages.txt"
    echo "pip3 packages backed up"
fi

# 5. KVM/QEMU setup
echo "5. Checking KVM/QEMU..."
if command -v virsh &> /dev/null; then
    # List installed virtualization packages
    rpm -qa | grep -E 'qemu|libvirt|virt-' > "$OUTPUT_DIR/kvm_packages.txt"
    
    # Check if user is in libvirt group
    groups > "$OUTPUT_DIR/user_groups.txt"
    
    # Libvirt network config
    sudo virsh net-dumpxml default > "$OUTPUT_DIR/libvirt_default_network.xml" 2>/dev/null || echo "No default network" > "$OUTPUT_DIR/libvirt_default_network.xml"
    
    echo "KVM/QEMU info backed up"
fi

# 6. Network interface for WiFi
echo "6. Detecting WiFi interface..."
WIFI_IF=$(ip route show default | grep -oP 'dev \K\w+' | head -1)
echo "WIFI_INTERFACE=$WIFI_IF" > "$OUTPUT_DIR/wifi_interface.txt"
echo "WiFi interface: $WIFI_IF"

# 7. Current iptables rules
echo "7. Backing up current iptables rules..."
sudo iptables-save > "$OUTPUT_DIR/iptables_current.rules"
# Filter for KVM-related rules
sudo iptables -t nat -L POSTROUTING -n -v | grep 192.168.124 > "$OUTPUT_DIR/iptables_kvm_nat.txt" 2>/dev/null || echo "No KVM NAT rules" > "$OUTPUT_DIR/iptables_kvm_nat.txt"
sudo iptables -L FORWARD -n -v | grep 192.168.124 > "$OUTPUT_DIR/iptables_kvm_forward.txt" 2>/dev/null || echo "No KVM FORWARD rules" > "$OUTPUT_DIR/iptables_kvm_forward.txt"

# 8. Check if libvirt hook exists
echo "8. Checking libvirt hooks..."
if [ -f /etc/libvirt/hooks/network ]; then
    sudo cp /etc/libvirt/hooks/network "$OUTPUT_DIR/libvirt_network_hook.sh"
    echo "Libvirt network hook backed up"
else
    echo "No libvirt network hook found"
fi

# 9. System services status
echo "9. Checking services..."
systemctl is-enabled firewalld > "$OUTPUT_DIR/firewalld_status.txt" 2>&1
systemctl is-enabled libvirtd > "$OUTPUT_DIR/libvirtd_status.txt" 2>&1

echo ""
echo "=== Discovery Complete! ==="
echo "All info saved in: $OUTPUT_DIR/"
echo ""
echo "Review files:"
ls -lh "$OUTPUT_DIR/"