# Fedora Setup Automation

Automated backup and restore of your Fedora setup using Ansible.

## Features

- KVM/QEMU with **fixed networking** (works after reboot)
- Hyper terminal
- GNOME extensions and settings
- pip3 packages
- NFS mounts
- Automatic network interface detection

## Usage

### 1. Backup Current System
```bash
./discover.sh
```

This creates `my_setup/` directory with all your configurations.

### 2. Fresh Install

After reinstalling Fedora:
```bash
# Install Ansible
sudo dnf install -y ansible

# Copy your backup
cp -r /path/to/my_setup .

# Run restoration
ansible-playbook site.yml
```

### 3. Logout and Login

Group changes require logout/login to take effect.

## Run Specific Roles
```bash
# Only KVM setup
ansible-playbook site.yml --tags kvm

# Only desktop apps
ansible-playbook site.yml --tags hyper,gnome

# Multiple roles
ansible-playbook site.yml --tags kvm,pip
```

## Available Tags

- `kvm` - KVM/QEMU virtualization
- `hyper` - Hyper terminal
- `gnome` - GNOME extensions
- `pip` - Python packages
- `nfs` - NFS mounts

## Verification

After running, verify:
```bash
# Check network
sudo virsh net-list

# Test after reboot
sudo reboot
# After reboot:
sudo virsh net-list  # Should show "default active"
```

## Directory Structure
```
fedora-setup/
├── site.yml              # Main playbook
├── discover.sh           # Backup script
├── group_vars/
│   └── all.yml          # Variables
├── roles/
│   ├── kvm/
│   ├── hyper/
│   ├── gnome/
│   ├── pip3/
│   └── nfs/
└── my_setup/            # Your backups
```