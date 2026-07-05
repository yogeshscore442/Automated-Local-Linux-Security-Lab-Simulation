#!/bin/bash
# mega_os_lab.sh
# Autonomous Local Linux Security Lab Simulation Provisioning Script
# Target Environment: Debian / Kali Linux
# Must be executed with root privileges (sudo)

set -e

# ANSI Color Sequences
GREEN='\e[1;32m'
BLUE='\e[1;34m'
RED='\e[1;31m'
NC='\e[0m' # No Color

echo -e "${BLUE}[*] Starting mega_os_lab.sh provisioning script...${NC}"

# 1. Privilege Check
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Error: This script must be run with root privileges (sudo).${NC}"
  exit 1
fi

# 2. Lab User Configuration
LAB_USER="hackathon_lab"
LAB_PASS="lab123"
HOME_DIR="/home/${LAB_USER}"

echo -e "${BLUE}[*] Provisioning isolated training user '${LAB_USER}'...${NC}"
if id "$LAB_USER" &>/dev/null; then
  echo -e "${BLUE}[*] User '${LAB_USER}' already exists. Updating password...${NC}"
else
  useradd -m -s /bin/bash "$LAB_USER"
fi
echo "${LAB_USER}:${LAB_PASS}" | chpasswd

# Initialize directories
mkdir -p "$HOME_DIR"
chown "$LAB_USER:$LAB_USER" "$HOME_DIR"

# Clean up stale mock network listeners from previous runs
echo -e "${BLUE}[*] Cleaning up any stale mock listeners...${NC}"
pkill -f "127.0.0.1.*4444" || true
pkill -f "ipc.sock" || true

# Helper function to initialize PS directory tree
init_ps_dirs() {
  local ps=$1
  mkdir -p "${HOME_DIR}/${ps}/easy"
  mkdir -p "${HOME_DIR}/${ps}/medium"
  mkdir -p "${HOME_DIR}/${ps}/hard"
}

# ==========================================
# PS-01: Kernel and System Call Security
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-01: Kernel and System Call Security...${NC}"
init_ps_dirs "PS-01"

cat << 'EOF' > "${HOME_DIR}/PS-01/README.md"
# PS-01: Kernel and System Call Security

## THE MOTIVE
Auditing the boundary between user-space and kernel-space is essential to prevent local privilege escalation (LPE). System parameters (sysctl), symbol resolution listings, profiling interfaces, and signal handlers can leak memory layouts or permit kernel execution manipulation.

## REQUIRED CLI SKILLS
- sysctl
- cat
- modinfo
- dmesg
- strace
- ipcs

## LAB OBJECTIVE
Audit system parameter structures, discover kernel debugging leakages, and identify unsafe profiling environments to recover Flag inputs.
EOF

# Easy
echo "kernel.core_pattern = /tmp/core-%e-%p-%t # Flag{PS01_L01_CORE_DUMP_LEAK}" > "${HOME_DIR}/PS-01/easy/core_pattern_backup"
echo "kernel.sysrq = 1" > "${HOME_DIR}/PS-01/easy/sysctl_backup.conf"
echo "Flag{PS01_L02_PROC_SYS_EXPOSURE}" >> "${HOME_DIR}/PS-01/easy/sysctl_backup.conf"
echo "Flag{PS01_L03_DMESG_READ}" > "${HOME_DIR}/PS-01/easy/mock_dmesg.log"
chmod 644 "${HOME_DIR}/PS-01/easy/mock_dmesg.log"

# Medium
echo "0000000000000000 d _text" > "${HOME_DIR}/PS-01/medium/kallsyms_leak.txt"
echo "Flag{PS01_L04_KPTR_RESTRICT_LEAK}" >> "${HOME_DIR}/PS-01/medium/kallsyms_leak.txt"
echo "filename: mock_driver.ko" > "${HOME_DIR}/PS-01/medium/modinfo_dump.txt"
echo "Flag{PS01_L05_CUSTOM_MODULE_DUMP}" >> "${HOME_DIR}/PS-01/medium/modinfo_dump.txt"
echo "perf_event_paranoid = -1 # Flag{PS01_L06_SYSCALL_PROFILING}" > "${HOME_DIR}/PS-01/medium/perf_event_paranoid_backup.txt"

# Hard
echo "shmid owner perms bytes" > "${HOME_DIR}/PS-01/hard/shm_leaks.txt"
echo "0x00001 root 666 4096 Flag{PS01_L07_SHM_SEGMENT_LEAK}" >> "${HOME_DIR}/PS-01/hard/shm_leaks.txt"
echo '{"signal": "SIGSEGV", "action": "dump_flag", "flag": "Flag{PS01_L08_SIGNAL_TRAP_MISCONFIG}"}' > "${HOME_DIR}/PS-01/hard/signal_trap_config.json"


# ==========================================
# PS-02: Authentication, Access Control, and Privilege Management
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-02: Authentication, Access Control, and Privilege Management...${NC}"
init_ps_dirs "PS-02"

cat << 'EOF' > "${HOME_DIR}/PS-02/README.md"
# PS-02: Authentication and Privilege Management

## THE MOTIVE
Ineffective permissions, overly permissive sudo boundaries, and assigned Linux Capabilities are prime vectors for local privilege escalation (LPE). Security teams must verify least privilege enforcement across all administrative interfaces.

## REQUIRED CLI SKILLS
- find
- sudo
- getcap
- getent

## LAB OBJECTIVE
Investigate SUID binaries, wildcards in sudo configurations, and assigned capabilities to escalate privileges and read root flag targets.
EOF

# Easy
# Copy a utility and set SUID
cp /usr/bin/awk "${HOME_DIR}/PS-02/easy/suid_awk"
chown root:root "${HOME_DIR}/PS-02/easy/suid_awk"
chmod 4755 "${HOME_DIR}/PS-02/easy/suid_awk"
echo "Flag{PS02_L01_SUID_AWK}" > /root/ps02_flag.txt
chmod 600 /root/ps02_flag.txt

# Alias injection file
echo 'alias check_status="echo '\''System ok'\''; # Flag{PS02_L02_WRITABLE_PROFILE}"' > /etc/profile.d/hackathon_lab.sh
chmod 777 /etc/profile.d/hackathon_lab.sh

# Umask configuration
echo "umask 000 # Flag{PS02_L03_INSECURE_UMASK}" >> "${HOME_DIR}/.bashrc"

# Medium
# Sudoers rules wildcard configuration
echo "hackathon_lab ALL=(ALL) NOPASSWD: /usr/bin/cat ${HOME_DIR}/PS-02/medium/*" > /etc/sudoers.d/hackathon_lab
chmod 0440 /etc/sudoers.d/hackathon_lab
echo "Flag{PS02_L04_SUDO_WILDCARD}" > "${HOME_DIR}/PS-02/medium/flag.txt"
chmod 600 "${HOME_DIR}/PS-02/medium/flag.txt"
chown root:root "${HOME_DIR}/PS-02/medium/flag.txt"

# PAM configuration parameters mock
echo "auth optional pam_faildelay.so delay=2000000 # Flag{PS02_L05_PAM_MISCONFIG}" > "${HOME_DIR}/PS-02/medium/pam.conf"

# Group writable path binary
mkdir -p "${HOME_DIR}/PS-02/medium/bin"
echo -e '#!/bin/bash\necho "Status Check: Flag{PS02_L06_GROUP_WRITABLE_BIN}"' > "${HOME_DIR}/PS-02/medium/bin/status_check"
chmod 775 "${HOME_DIR}/PS-02/medium/bin/status_check"
chown -R root:hackathon_lab "${HOME_DIR}/PS-02/medium/bin"

# Hard
# Capabilities python
cp /usr/bin/python3 "${HOME_DIR}/PS-02/hard/cap_python"
chown root:root "${HOME_DIR}/PS-02/hard/cap_python"
if command -v setcap &>/dev/null; then
  setcap cap_setuid+ep "${HOME_DIR}/PS-02/hard/cap_python"
fi
echo "Flag{PS02_L07_CAP_SETUID}" > "${HOME_DIR}/PS-02/hard/cap_flag.txt"
chmod 600 "${HOME_DIR}/PS-02/hard/cap_flag.txt"

# Shadow group script execution
echo -e '#!/bin/bash\n# Executed with group shadow\n# Flag{PS02_L08_SHADOW_GROUP_INJECTION}' > "${HOME_DIR}/PS-02/hard/shadow_runner.sh"
chown root:shadow "${HOME_DIR}/PS-02/hard/shadow_runner.sh"
chmod 775 "${HOME_DIR}/PS-02/hard/shadow_runner.sh"


# ==========================================
# PS-03: Package Management and Software Supply Chain
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-03: Package Management and Software Supply Chain...${NC}"
init_ps_dirs "PS-03"

cat << 'EOF' > "${HOME_DIR}/PS-03/README.md"
# PS-03: Package Management and Software Supply Chain

## THE MOTIVE
Package integrity determines the baseline trust of system executables. Untrusted sources lists, weak signatures, writable system caches, and compromised package management hooks can allow persistent code injection.

## REQUIRED CLI SKILLS
- apt
- dpkg
- pip
- ldd

## LAB OBJECTIVE
Identify registry/mirror misconfigurations, post-install trigger bypasses, python packaging entrypoints, and library preload hijack vectors.
EOF

# Easy
echo "deb http://untrusted-mirror.local/debian stable main # Flag{PS03_L01_UNTRUSTED_MIRROR}" > "${HOME_DIR}/PS-03/easy/sources.list"
echo "Flag{PS03_L02_UNVERIFIED_GPG}" > "${HOME_DIR}/PS-03/easy/unverified_gpg.key"
mkdir -p "${HOME_DIR}/PS-03/easy/apt_cache"
chmod 777 "${HOME_DIR}/PS-03/easy/apt_cache"
echo "Flag{PS03_L03_WRITABLE_CACHE}" > "${HOME_DIR}/PS-03/easy/apt_cache/flag.txt"

# Medium
echo 'DPkg::Post-Invoke {"/home/hackathon_lab/PS-03/medium/post_install.sh";}; # Flag{PS03_L04_DPKG_HOOK}' > "${HOME_DIR}/PS-03/medium/99hook"
echo -e "Package: badpkg\nStatus: install ok installed\nFlag: Flag{PS03_L05_DPKG_STATUS_POISON}" > "${HOME_DIR}/PS-03/medium/status_mock"
echo -e 'from setuptools import setup\n# Flag{PS03_L06_PIP_ENTRYPOINT}' > "${HOME_DIR}/PS-03/medium/setup_mock.py"

# Hard
echo 'Acquire::http::Proxy "http://attacker-proxy:8080"; # Flag{PS03_L07_APT_PROXY}' > "${HOME_DIR}/PS-03/hard/proxy.conf"
mkdir -p "${HOME_DIR}/PS-03/hard/libs"
echo "Flag{PS03_L08_LD_PRELOAD_SO}" > "${HOME_DIR}/PS-03/hard/libs/flag.txt"


# ==========================================
# PS-04: Network Stack, Services, and Firewall
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-04: Network Stack, Services, and Firewall...${NC}"
init_ps_dirs "PS-04"

cat << 'EOF' > "${HOME_DIR}/PS-04/README.md"
# PS-04: Network Stack, Services, and Firewall

## THE MOTIVE
Exposed background processes, weak service configurations, and poor firewall isolation rules can bypass edge boundaries, allowing remote or local pivot access.

## REQUIRED CLI SKILLS
- ss
- netstat
- iptables
- nc
- showmount

## LAB OBJECTIVE
Audit the running loopback listeners, investigate firewall bypasses, and access internal IPC sockets.
EOF

# Easy
# Start python network listener on 127.0.0.1:4444 (Safe local interface binding)
nohup python3 -c '
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 4444))
s.listen(5)
while True:
    try:
        conn, addr = s.accept()
        conn.sendall(b"Flag{PS04_L01_NC_BACKDOOR}\n")
        conn.close()
    except:
        pass
' >/dev/null 2>&1 &

echo "Listen 0.0.0.0:8080 # Flag{PS04_L02_PUBLIC_BINDING}" > "${HOME_DIR}/PS-04/easy/service.conf"
echo "bantime = 10s # Flag{PS04_L03_WEAK_TIMEOUT}" > "${HOME_DIR}/PS-04/easy/fail2ban.conf"

# Medium
echo "-A INPUT -p tcp --dport 22 -j ACCEPT # Flag{PS04_L04_FIREWALL_BYPASS}" > "${HOME_DIR}/PS-04/medium/iptables.rules"
echo "PermitEmptyPasswords yes # Flag{PS04_L05_INSECURE_SSH}" > "${HOME_DIR}/PS-04/medium/sshd_config"
echo "127.0.0.1 local-dev.server # Flag{PS04_L06_DNS_SPOOF}" > "${HOME_DIR}/PS-04/medium/hosts_backup"

# Hard
echo "/opt/nfs *(rw,no_root_squash) # Flag{PS04_L07_NFS_ROOT_SQUASH}" > "${HOME_DIR}/PS-04/hard/exports_leak"
# Unix Socket IPC listener
nohup python3 -c '
import socket, os
socket_path = "/home/hackathon_lab/PS-04/hard/ipc.sock"
if os.path.exists(socket_path):
    os.remove(socket_path)
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(socket_path)
os.chmod(socket_path, 0o666)
s.listen(5)
while True:
    try:
        conn, addr = s.accept()
        conn.sendall(b"Flag{PS04_L08_IPC_SOCKET_LEAK}\n")
        conn.close()
    except:
        pass
' >/dev/null 2>&1 &


# ==========================================
# PS-05: Boot Process, GRUB, and Secure Boot
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-05: Boot Process, GRUB, and Secure Boot...${NC}"
init_ps_dirs "PS-05"

cat << 'EOF' > "${HOME_DIR}/PS-05/README.md"
# PS-05: Boot Process, GRUB, and Secure Boot

## THE MOTIVE
Compromising the boot sequence allows root takeover before standard access controls execute. Auditing boot arguments, custom initramfs hooks, systemd services, and reboot schedulers is essential.

## REQUIRED CLI SKILLS
- systemctl
- crontab
- lsinitramfs

## LAB OBJECTIVE
Investigate plaintext grub backups, writable unit files, and custom persistent initramfs environments.
EOF

# Easy
echo "password_pbkdf2 root Flag{PS05_L01_GRUB_PLAINTEXT}" > "${HOME_DIR}/PS-05/easy/grub_backup.cfg"
echo "INIT_DEBUG=1 # Flag{PS05_L02_INIT_PARAMS}" > "${HOME_DIR}/PS-05/easy/init_params.txt"
echo "AllowRescueMode=yes # Flag{PS05_L03_RESCUE_MODE}" > "${HOME_DIR}/PS-05/easy/systemd_rescue.conf"

# Medium
echo -e '[Service]\nExecStart=/tmp/backdoor.sh\n# Flag{PS05_L04_WRITABLE_SERVICE}' > "${HOME_DIR}/PS-05/medium/backdoor.service"
chmod 777 "${HOME_DIR}/PS-05/medium/backdoor.service"
echo "@reboot /home/hackathon_lab/startup.sh # Flag{PS05_L05_CRON_REBOOT}" > "${HOME_DIR}/PS-05/medium/crontab_backup"
echo "blacklist pcspkr # Flag{PS05_L06_MODULE_BLACKLIST}" > "${HOME_DIR}/PS-05/medium/modprobe_blacklist.conf"

# Hard
echo -e '#!/bin/sh\n# Custom initramfs hook\n# Flag{PS05_L07_INITRAMFS_HIJACK}' > "${HOME_DIR}/PS-05/hard/initramfs_hook"
echo "GRUB_ENV_PERSIST=true # Flag{PS05_L08_BOOTLOADER_PERSISTENCE}" > "${HOME_DIR}/PS-05/hard/grubenv"


# ==========================================
# PS-06: Desktop Environment and GUI Layer
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-06: Desktop Environment and GUI Layer...${NC}"
init_ps_dirs "PS-06"

cat << 'EOF' > "${HOME_DIR}/PS-06/README.md"
# PS-06: Desktop Environment and GUI Layer

## THE MOTIVE
GUI sessions carry highly sensitive data, including authentication keys and clipboards. Misconfigured Xorg configs, auto-logins, or exposed desktop session keys can allow unprivileged processes to execute commands or leak inputs.

## REQUIRED CLI SKILLS
- dbus-send
- xauth

## LAB OBJECTIVE
Find insecure Xauthority files, exposed remote passwords, and permissive D-Bus IPC rules.
EOF

# Easy
echo "Flag{PS06_L01_XAUTHORITY_READ}" > "${HOME_DIR}/PS-06/easy/.Xauthority_backup"
chmod 644 "${HOME_DIR}/PS-06/easy/.Xauthority_backup"
echo "xhost + # Flag{PS06_L02_XINITRC}" > "${HOME_DIR}/PS-06/easy/xinitrc_global"
echo "autologin-user=hackathon_lab # Flag{PS06_L03_AUTOLOGIN}" > "${HOME_DIR}/PS-06/easy/lightdm_autologin.conf"

# Medium
echo "Password: Flag{PS06_L04_VNC_CREDENTIALS}" > "${HOME_DIR}/PS-06/medium/vnc_passwd"
echo -e 'Section "Device"\n  Mode "WriteAll" # Flag{PS06_L05_WRITABLE_XORG}\nEndSection' > "${HOME_DIR}/PS-06/medium/xorg.conf"
chmod 777 "${HOME_DIR}/PS-06/medium/xorg.conf"
echo "Clipboard: api_key=123 # Flag{PS06_L06_CLIPBOARD_LEAK}" > "${HOME_DIR}/PS-06/medium/clipboard_dump.txt"

# Hard
echo -e '<policy user="*">\n  <allow send_destination="*"/>\n  <!-- Flag{PS06_L07_DBUS_POLICY} -->\n</policy>' > "${HOME_DIR}/PS-06/hard/dbus_policy.conf"
echo -e '[Desktop Entry]\nExec=/tmp/persist.sh\n# Flag{PS06_L08_DESKTOP_PERSISTENCE}' > "${HOME_DIR}/PS-06/hard/autostart_backdoor.desktop"


# ==========================================
# PS-07: File System, Permissions, and Storage
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-07: File System, Permissions, and Storage...${NC}"
init_ps_dirs "PS-07"

cat << 'EOF' > "${HOME_DIR}/PS-07/README.md"
# PS-07: File System, Permissions, and Storage

## THE MOTIVE
Improper directory structure permissions can compromise isolation boundaries. Auditing world-writable scripts, sticky bits, symbolic links, and orphaned files is vital to preventing privilege boundary bypasses.

## REQUIRED CLI SKILLS
- find
- df
- ls
- mount

## LAB OBJECTIVE
Find globally writable scripts, resolve deceptive symlinks to privileged files, and isolate orphaned system files.
EOF

# Easy
echo -e '#!/bin/bash\n# Maintenance script\n# Flag{PS07_L01_WRITABLE_SCRIPT}' > "${HOME_DIR}/PS-07/easy/backup.sh"
chmod 777 "${HOME_DIR}/PS-07/easy/backup.sh"
mkdir -p "${HOME_DIR}/PS-07/easy/lost+found"
echo "INSERT INTO users VALUES ('admin', 'Flag{PS07_L02_LOST_FOUND_DB}');" > "${HOME_DIR}/PS-07/easy/lost+found/db_backup.sql"
echo "Flag{PS07_L03_TMP_SENSITIVE}" > "/tmp/sensitive_passwords.txt"
chmod 644 "/tmp/sensitive_passwords.txt"

# Medium
# restricted target file for symlink validation
echo "Flag{PS07_L04_DECEPTIVE_SYMLINK}" > /root/shadow_copy
chmod 600 /root/shadow_copy
ln -sf /root/shadow_copy "${HOME_DIR}/PS-07/medium/root_link"

mkdir -p "${HOME_DIR}/PS-07/medium/shared_project"
chmod 777 "${HOME_DIR}/PS-07/medium/shared_project"
echo "Flag{PS07_L05_STICKY_BIT_MISSING}" > "${HOME_DIR}/PS-07/medium/shared_project/info.txt"
echo "Flag{PS07_L06_SHADOW_PROFILE}" > "${HOME_DIR}/PS-07/medium/.shadow_profile"

# Hard
echo "Flag{PS07_L07_ORPHANED_UID}" > "${HOME_DIR}/PS-07/hard/orphaned_file"
chown 9999:9999 "${HOME_DIR}/PS-07/hard/orphaned_file"
echo "/dev/loop0 /mnt/ext4 rw,noexec # Flag{PS07_L08_LOOP_MOUNT}" > "${HOME_DIR}/PS-07/hard/loop_mount_info"


# ==========================================
# PS-08: Logging, Auditing, and Monitoring
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-08: Logging, Auditing, and Monitoring...${NC}"
init_ps_dirs "PS-08"

cat << 'EOF' > "${HOME_DIR}/PS-08/README.md"
# PS-08: Logging, Auditing, and Monitoring

## THE MOTIVE
Log configurations and audit profiles provide dynamic host operational benchmarks. Misconfigured log permissions or customized auditd rule suppressions allow attackers to bypass monitoring.

## REQUIRED CLI SKILLS
- journalctl
- auditctl
- grep

## LAB OBJECTIVE
Examine application debug logs, discover rsyslog bypass routes, and audit active log rotation properties.
EOF

# Easy
echo "*.* ~ # Flag{PS08_L01_RSYSLOG_BYPASS}" > "${HOME_DIR}/PS-08/easy/rsyslog_bypass.conf"
echo "Flag{PS08_L02_UNROTATED_LOGS}" > "${HOME_DIR}/PS-08/easy/auth_huge.log"
chmod 644 "${HOME_DIR}/PS-08/easy/auth_huge.log"
echo "history -c # Flag{PS08_L03_CLEARED_HISTORY}" > "${HOME_DIR}/PS-08/easy/.bash_history_mock"

# Medium
echo "DB_CONN=mysql://root:Flag{PS08_L04_HARDCODED_LOG_CREDS}@localhost/db" > "${HOME_DIR}/PS-08/medium/app_debug.log"
echo "Storage=volatile # Flag{PS08_L05_JOURNAL_PERMS}" > "${HOME_DIR}/PS-08/medium/journal.conf"
echo "-a never,exit -S all # Flag{PS08_L06_AUDITD_SUPPRESSION}" > "${HOME_DIR}/PS-08/medium/audit.rules"

# Hard
echo "Buffer log dump # Flag{PS08_L07_IN_MEMORY_LOGS}" > "${HOME_DIR}/PS-08/hard/ram_log_buffer"
echo "active = no # Flag{PS08_L08_DISABLED_AUDITING}" > "${HOME_DIR}/PS-08/hard/auditd.conf"


# ==========================================
# PS-09: Cryptographic Implementation and Configuration
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-09: Cryptographic Implementation and Configuration...${NC}"
init_ps_dirs "PS-09"

cat << 'EOF' > "${HOME_DIR}/PS-09/README.md"
# PS-09: Cryptographic Implementation and Configuration

## THE MOTIVE
Ineffective encryption architectures expose active credentials and configurations. Weak algorithms, saltless hashes, unprotected certificates, and hardcoded secrets allow cryptanalytic compromise.

## REQUIRED CLI SKILLS
- openssl
- hashcat
- john

## LAB OBJECTIVE
Identify plaintext private identity keys, locate and crack legacy hash archives, and resolve TLS downgrades.
EOF

# Easy
echo -e '-----BEGIN RSA PRIVATE KEY-----\nFlag{PS09_L01_LEGACY_SSH_KEY}\n-----END RSA PRIVATE KEY-----' > "${HOME_DIR}/PS-09/easy/id_rsa_legacy"
echo "Certificate: Flag{PS09_L02_UNPROTECTED_CERT}" > "${HOME_DIR}/PS-09/easy/cert.pem"
echo "admin:21232f297a57a5a743894a0e4a801fc3 # Flag{PS09_L03_MD5_HASHES}" > "${HOME_DIR}/PS-09/easy/hashes.txt"

# Medium
echo "admin:a9993e364706816aba3e25717850c26c9cd0d89d # Flag{PS09_L04_SALTLESS_HASH}" > "${HOME_DIR}/PS-09/medium/saltless_hashes.db"
echo "AES_KEY=Flag{PS09_L05_SYMMETRIC_KEY}" > "${HOME_DIR}/PS-09/medium/aes.key"
echo "ssl_protocols SSLv3; # Flag{PS09_L06_SSL_MISCONFIG}" > "${HOME_DIR}/PS-09/medium/nginx_ssl.conf"

# Hard
echo "ssl_ciphers TLS1.0:TLS1.1 # Flag{PS09_L07_TLS_FALLBACK}" > "${HOME_DIR}/PS-09/hard/tls_fallback.conf"
echo -e '#!/usr/bin/env python3\nseed = "Flag{PS09_L08_HARDCODED_SEED}"\n' > "${HOME_DIR}/PS-09/hard/validate.py"


# ==========================================
# PS-10: Custom OS Extensibility Layer
# ==========================================
echo -e "${BLUE}[*] Provisioning PS-10: Custom OS Extensibility Layer...${NC}"
init_ps_dirs "PS-10"

cat << 'EOF' > "${HOME_DIR}/PS-10/README.md"
# PS-10: Custom OS Extensibility Layer

## THE MOTIVE
Local administrative scripts and extensibility features run regularly with high system context. Input validation omissions, sandboxing bypasses, and argument wildcard expansions present high-impact attack surfaces.

## REQUIRED CLI SKILLS
- lsof
- python3
- tar

## LAB OBJECTIVE
Investigate administrative extension repositories, exploit command wildcards, and bypass validation modules.
EOF

# Easy
echo "LegacyParam=Flag{PS10_L01_LEGACY_CONFIG}" > "${HOME_DIR}/PS-10/easy/legacy.conf"
echo "BASE_MARKER=Flag{PS10_L02_ENV_MARKER}" > "${HOME_DIR}/PS-10/easy/.env_marker"
mkdir -p "${HOME_DIR}/PS-10/easy/scripts"
chmod 777 "${HOME_DIR}/PS-10/easy/scripts"
echo "Flag{PS10_L03_WRITABLE_REPO}" > "${HOME_DIR}/PS-10/easy/scripts/repo.txt"

# Medium
echo '{"disable_namespaces": true} # Flag{PS10_L04_SANDBOX_BYPASS}' > "${HOME_DIR}/PS-10/medium/sandbox.json"
echo -e '#!/bin/bash\ntar -cf backup.tar * # Flag{PS10_L05_WILDCARD_INJECTION}' > "${HOME_DIR}/PS-10/medium/backup_util.sh"
echo "AdminPort: 9000 # Flag{PS10_L06_ADMIN_SERVICE}" > "${HOME_DIR}/PS-10/medium/admin.conf"

# Hard
mkdir -p "${HOME_DIR}/PS-10/hard/tenant_A"
mkdir -p "${HOME_DIR}/PS-10/hard/tenant_B"
echo "Flag{PS10_L07_TENANT_LEAK}" > "${HOME_DIR}/PS-10/hard/tenant_A/leak.txt"
chmod 777 "${HOME_DIR}/PS-10/hard/tenant_A/leak.txt"

# Command Injection target setup
cat << 'EOF' > "${HOME_DIR}/PS-10/hard/monitor.py"
#!/usr/bin/env python3
import sys, os

if len(sys.argv) < 2:
    print("Usage: monitor.py <host>")
    sys.exit(1)

host = sys.argv[1]
# Vulnerable to command injection via shell expansion
os.system(f"ping -c 1 {host}")
EOF
chmod +x "${HOME_DIR}/PS-10/hard/monitor.py"
chown root:root "${HOME_DIR}/PS-10/hard/monitor.py"

# Escalate rule in sudoers for monitor.py validation target
echo "hackathon_lab ALL=(root) NOPASSWD: /home/hackathon_lab/PS-10/hard/monitor.py" >> /etc/sudoers.d/hackathon_lab
echo "Flag{PS10_L08_COMMAND_INJECTION}" > /root/ps10_flag.txt
chmod 600 /root/ps10_flag.txt


# ==========================================
# 4. Final Permissions Setup
# ==========================================
echo -e "${BLUE}[*] Adjusting final owners and execution bits...${NC}"

# User folder ownership
chown -R "$LAB_USER:$LAB_USER" "$HOME_DIR"

# Explicit root ownership restore for SUID/privilege escalation scenarios
chown root:root "${HOME_DIR}/PS-02/easy/suid_awk"
chmod 4755 "${HOME_DIR}/PS-02/easy/suid_awk"

chown root:root "${HOME_DIR}/PS-02/medium/flag.txt"
chmod 600 "${HOME_DIR}/PS-02/medium/flag.txt"

chown root:root "${HOME_DIR}/PS-02/hard/cap_python"
if command -v setcap &>/dev/null; then
  setcap cap_setuid+ep "${HOME_DIR}/PS-02/hard/cap_python"
fi
chown root:root "${HOME_DIR}/PS-02/hard/cap_flag.txt"
chmod 600 "${HOME_DIR}/PS-02/hard/cap_flag.txt"

chown root:shadow "${HOME_DIR}/PS-02/hard/shadow_runner.sh"
chmod 775 "${HOME_DIR}/PS-02/hard/shadow_runner.sh"

chown root:root "${HOME_DIR}/PS-10/hard/monitor.py"
chmod +x "${HOME_DIR}/PS-10/hard/monitor.py"

# Symbolic link ownership logic
chown -h "$LAB_USER:$LAB_USER" "${HOME_DIR}/PS-07/medium/root_link"

echo -e "${GREEN}[+] Lab environment provisioned successfully!${NC}"
echo -e "${GREEN}[+] Target Path: ${HOME_DIR}${NC}"
echo -e "${GREEN}[+] Training Account Username: ${LAB_USER}${NC}"
echo -e "${GREEN}[+] Training Account Password: ${LAB_PASS}${NC}"
