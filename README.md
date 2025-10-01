# journal-cleanup-ansible

Automated deployment of systemd journal cleanup service for Linux devices using Ansible. Configures daily automatic journal vacuum to free up RAM and disk space.

## 📋 Overview

This project deploys a systemd timer that automatically cleans the systemd journal on multiple devices simultaneously. The cleanup runs daily at 00:01 UTC, maintaining journal size under control.

**Journal cleanup settings:**
- Maximum size: 20MB
- Maximum age: 10 days

## 🚀 Features

- ✅ Automated deployment to multiple devices in parallel
- ✅ Intelligent skip for already-configured devices
- ✅ Legacy SSH support (ssh-rsa) for older Linux systems
- ✅ Connection timeout handling
- ✅ Detailed deployment status reporting
- ✅ Idempotent execution (safe to run multiple times)

## 📁 Project Structure

```
.
├── ansible.cfg                    # Ansible configuration
├── deploy.yml                     # Main deployment playbook
├── inventory.yml                  # Device inventory (IPs and credentials)
├── run-deployment.sh              # Deployment executor script
├── check-status.yml               # Status verification playbook (optional)
└── files/
    ├── vacuum-journal.service     # Systemd service unit
    └── vacuum-journal.timer       # Systemd timer unit
```

## 🔧 Prerequisites

### On control machine (where you run Ansible):
```bash
sudo apt update
sudo apt install ansible sshpass wireguard
```

### Network requirements:
- **Active VPN connection** - Devices may only be accessible through VPN
- Valid VPN configuration with proper certificates
- VPN must be connected before running deployment

### Target devices requirements:
- SSH access as root
- systemd-based Linux system
- Python 2.7 or Python 3.x
- Network accessibility from control machine

## ⚙️ Configuration

### 1. Connect to VPN (if required)

**IMPORTANT:** If devices are only accessible through VPN, ensure connection is active before deployment:

```bash
# Check VPN status
sudo wg show

# Start VPN connection (adjust interface name as needed)
sudo wg-quick up <vpn-interface>

# Verify you can reach the network
ping <target-ip>
```

### 2. Configure device inventory

Edit `inventory.yml` and add your device IPs:

```yaml
all:
  children:
    pd_devices:
      hosts:
        <device-ip-1>:
        <device-ip-2>:
        <device-ip-3>:
        # Add more IPs here
      vars:
        ansible_user: root
        ansible_ssh_pass: <your-password>
        ansible_host_key_checking: false
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
```

### 3. Update credentials

Change `ansible_ssh_pass` in `inventory.yml` to match your devices' root password.

## 🚀 Usage

### Quick deployment
```bash
chmod +x run-deployment.sh
./run-deployment.sh
```

### Manual deployment
```bash
ansible-playbook deploy.yml -v
```

### Check connectivity before deployment
```bash
ansible pd_devices -m ping
```

### Verify timer status on all devices
```bash
ansible-playbook check-status.yml
```

### Deploy to specific devices only
```bash
ansible-playbook deploy.yml --limit "<device-ip-1>,<device-ip-2>"
```

### Exclude specific devices
```bash
ansible-playbook deploy.yml --limit "pd_devices:!<device-ip>"
```

## 📊 Deployment Process

The playbook performs these steps on each device:

1. **Test connection** - Verify device is reachable
2. **Check existing configuration** - Skip if already configured
3. **Copy service files** - Transfer systemd unit files
4. **Enable and start timer** - Activate the scheduled cleanup
5. **Verify activation** - Confirm timer is running

## ✅ Verification

### Check timer status on all devices
```bash
ansible pd_devices -m shell -a "systemctl status vacuum-journal.timer"
```

### View next scheduled execution
```bash
ansible pd_devices -m shell -a "systemctl list-timers vacuum-journal.timer --no-pager"
```

### Manually trigger cleanup (for testing)
```bash
ansible pd_devices -m shell -a "systemctl start vacuum-journal.service"
```

### Check journal size
```bash
ansible pd_devices -m shell -a "journalctl --disk-usage"
```

## 🔍 Example Output

```
PLAY RECAP
<device-ip-1>    : ok=5    changed=2    unreachable=0    failed=0    skipped=1
<device-ip-2>    : ok=5    changed=2    unreachable=0    failed=0    skipped=1
<device-ip-3>    : ok=3    changed=0    unreachable=0    failed=0    skipped=0

✓ Deployment completed successfully
```

**Status meanings:**
- `changed=2` - Device was configured successfully
- `changed=0` - Device already had timer configured (skipped)
- `unreachable=1` - Device couldn't be reached (offline or network issue)

## 🛠️ Troubleshooting

### VPN not connected
```bash
# Check VPN status
sudo wg show

# Check if VPN interface is up
ip addr show <vpn-interface>

# Restart VPN if needed
sudo wg-quick down <vpn-interface>
sudo wg-quick up <vpn-interface>

# Test connectivity to devices
ping <target-ip>
```

### Connection timeout
```bash
# Test individual device
ping <target-ip>
ssh root@<target-ip>
```

### SSH key negotiation failed
The playbook includes legacy SSH support. If issues persist, verify device SSH configuration:
```bash
ssh -v root@<target-ip>
```

### Check Ansible debug output
```bash
ansible-playbook deploy.yml -vvv
```

### Verify Python on target device
```bash
ansible pd_devices -m shell -a "python --version || python3 --version"
```

## 📝 Customization

### Change cleanup schedule

Edit `files/vacuum-journal.timer`:
```ini
[Timer]
OnCalendar=*-*-* 02:00:00  # Run at 2:00 AM instead
```

### Change retention settings

Edit `files/vacuum-journal.service`:
```ini
[Service]
ExecStart=/bin/journalctl --vacuum-size=50M --vacuum-time=30d
```

After changes, redeploy:
```bash
./run-deployment.sh
```

## 🔒 Security Notes

- **VPN access**: Devices may be isolated behind VPN - ensure you have valid certificates and configuration
- **VPN certificates**: Keep VPN private keys secure and never commit to repository
- **Password in inventory**: Consider using Ansible Vault to encrypt credentials
- **SSH strict host checking**: Disabled for convenience; enable in production if needed
- **Root access**: Required for systemd service management

### VPN Configuration
Ensure your VPN configuration includes:
- Valid private key
- Proper peer configuration for device network
- Correct endpoint and allowed IPs

**Never commit VPN certificates or private keys to the repository.**

### Using Ansible Vault (recommended for production)
```bash
# Encrypt inventory file
ansible-vault encrypt inventory.yml

# Run with vault password
ansible-playbook deploy.yml --ask-vault-pass
```

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📧 Support

For issues or questions, please open a GitHub issue.