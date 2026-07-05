# Automated Local Linux Security Lab Simulation

A production-grade, automated Linux Security Lab environment designed for vulnerability research, privilege escalation auditing, and bug hunting practice. 

This repository contains `mega_os_lab.sh`, a shell provisioning script that sets up exactly **10 Problem Statements** across **80 distinct local vulnerabilities and misconfigurations** (easy, medium, and hard difficulty settings) inside a Debian-based host (e.g., Kali Linux).

---

## 🛠️ Lab Setup and Deployment

Follow these steps to deploy the lab environment on your target Kali/Debian host.

### Prerequisites

- A Debian-based Linux operating system (Kali Linux is highly recommended).
- Root privileges (`sudo` access).

### Step 1: Clone the Repository
Clone this repository to your local target machine:
```bash
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>
```

### Step 2: Make the Script Executable
Give the provisioning script execute permissions:
```bash
chmod +x mega_os_lab.sh
```

### Step 3: Run the Provisioning Script
Execute the script using `sudo` to configure the training account, directory matrix, challenge configurations, and local network ports:
```bash
sudo ./mega_os_lab.sh
```

### Step 4: Login to the Lab
Once the script completes successfully, switch to the isolated training user:
```bash
su - hackathon_lab
# Enter the password when prompted: lab123
```

---

## 📂 Lab Directory Matrix (10 Problem Statements)

Every subsystem configuration is located under `/home/hackathon_lab/` and includes its own `README.md` describing the security motive, required tools, and training goals.

1. **PS-01: Kernel and System Call Security**
   - Core dump patterns, system variables, module details, memory layouts, and signal parameters.
2. **PS-02: Authentication, Access Control, and Privilege Management**
   - SUID binaries, writable shell profiles, umask parameters, wildcards in sudo, PAM modules, and Capabilities.
3. **PS-03: Package Management and Software Supply Chain**
   - Untrusted mirror definitions, GPG registries, cache structures, post-invoke hooks, pip entrypoints, and library hijacking.
4. **PS-04: Network Stack, Services, and Firewall**
   - Unauthenticated listeners, loopback mappings, SSH config flags, firewall bypass rules, NFS configurations, and IPC sockets.
5. **PS-05: Boot Process, GRUB, and Secure Boot**
   - Grub backups, bootloader flags, writable systemd service files, cron reboot parameters, and initramfs hooks.
6. **PS-06: Desktop Environment and GUI Layer**
   - Session keys, xinitrc files, auto-logins, plaintext remote passwords, Xorg configurations, and D-Bus IPC rules.
7. **PS-07: File System, Permissions, and Storage**
   - Writable utility scripts, root file symlinks, missing sticky bits, orphaned system files, and loop storage mounts.
8. **PS-08: Logging, Auditing, and Monitoring**
   - Syslog drop parameters, huge log permissions, shell history deletions, credentials in app logs, and audit rules.
9. **PS-09: Cryptographic Implementation and Configuration**
   - Private SSH keys, self-signed certificates, MD5/SHA-1 hashes, symmetric key leaks, and static crypto seeds.
10. **PS-10: Custom OS Extensibility Layer**
    - Legacy parameters, environment indicators, writable scripts repositories, sandbox isolation bypasses, and command injection.

---

## 🚩 Flag Format

Each challenge features a target flag embedded within files or services:
`Flag{PSXX_LXX_DESCRIPTIVE_NAME}`

---

## 🚀 Uploading to GitHub

If you want to host this lab configuration on your GitHub account, run these commands from the local repository directory:

1. **Initialize git:**
   ```bash
   git init
   git add mega_os_lab.sh README.md
   git commit -m "Initial commit: Add automated Linux security lab provisioning files"
   ```

2. **Create a repository on GitHub** (e.g. named `linux-security-lab`).

3. **Link to your remote repository and push:**
   ```bash
   git branch -M main
   git remote add origin https://github.com/<your-username>/linux-security-lab.git
   git push -u origin main
   ```
