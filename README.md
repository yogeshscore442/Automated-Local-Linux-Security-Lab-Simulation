# Automated Local Linux Security Lab Simulation

An educational, production-grade Linux Security Lab simulation environment containing exactly **10 Problem Statements** across **80 distinct local vulnerabilities and misconfigurations** (easy, medium, and hard difficulty settings) inside a Debian-based host (e.g., Kali Linux).

This lab is built specifically for security enthusiasts, system administrators, and vulnerability researchers to practice local OS auditing, privilege escalation, and configuration review.

---

## 🛠️ Lab Setup and Deployment

Follow these steps to deploy the lab environment on your target Kali/Debian machine.

### Prerequisites
- A Debian-based Linux operating system (Kali Linux is highly recommended).
- Root privileges (`sudo` access).

### Step 1: Clone the Repository
Clone this repository to your local target machine:
```bash
git clone https://github.com/yogeshscore442/Automated-Local-Linux-Security-Lab-Simulation.git
cd Automated-Local-Linux-Security-Lab-Simulation
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

## 🎯 How to Use the Lab (Access & Discovery)

This lab is designed to be fully audited through the Command Line Interface (CLI). 

### 1. Finding Required Skills and Objectives
Each Problem Statement directory (`PS-01` to `PS-10`) contains a `README.md` file.
Before attacking any subsystem:
```bash
cat /home/hackathon_lab/PS-01/README.md
```
This document outlines:
- **THE MOTIVE**: Why this specific subsystem is critical to OS security.
- **REQUIRED CLI SKILLS**: The essential Linux tools you must use to discover the vulnerabilities.
- **LAB OBJECTIVE**: A high-level context guide pointing you toward Easy, Medium, and Hard vulnerability structures.

### 2. General Auditing Techniques

To solve the 80 challenges, you will need to apply various system administration and penetration testing techniques. Here are the core methodologies:

#### Technique A: Privilege Escalation Auditing
- **SUID/SGID Binaries**: Look for files that run with owner (root) privileges.
  ```bash
  find /home/hackathon_lab -perm -4000 -type f 2>/dev/null
  ```
- **Linux Capabilities**: Locate binaries with special capabilities assigned.
  ```bash
  getcap -r /home/hackathon_lab 2>/dev/null
  ```
- **Sudo Permissions**: List commands the user is allowed to run as root.
  ```bash
  sudo -l
  ```

#### Technique B: Network & Socket Auditing
- **TCP/UDP Socket Discovery**: Find active network services running on loopback ports.
  ```bash
  ss -tulpn
  # or
  netstat -antup
  ```
- **IPC Unix Sockets**: Inspect local inter-process communication sockets.
  ```bash
  ss -x -a
  # or
  lsof -U
  ```

#### Technique C: File System & Permissions Review
- **Writable Files**: Identify misconfigured scripts or directories that any user can write to.
  ```bash
  find /home/hackathon_lab -writable -type f 2>/dev/null
  ```
- **Sticky Bit Verification**: Audit shared directories to ensure users cannot delete files they do not own.
  ```bash
  ls -ld /home/hackathon_lab/PS-07/medium/shared_project
  ```
- **Symbolic Link Auditing**: Check if symlinks point to highly restricted files (like `/etc/shadow` or `/root`).
  ```bash
  ls -laR /home/hackathon_lab
  ```

#### Technique D: Cryptographic Auditing
- **Credentials & Key Harvesting**: Search for plaintext private key banners or hash algorithms.
  ```bash
  grep -rn "PRIVATE KEY" /home/hackathon_lab
  ```
- **Hash Analysis**: Identify weak MD5 or saltless hashes and attempt to crack them using standard tools like `john` or `hashcat`.

---

## 🚩 Flag Verification

Every successfully solved or audited challenge reveals a flag in the following format:
`Flag{PSXX_LXX_DESCRIPTIVE_NAME}`

For example:
- `Flag{PS02_L01_SUID_AWK}` represents **Problem Statement 2 (Access Control), Level 1 (Easy), awk privilege escalation**.
- Search files, capture command inputs, connect to sockets, or read privileged outputs to extract all 80 flags!
