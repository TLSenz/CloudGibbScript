#!/usr/bin/env python3
import os
import time
import subprocess
import paramiko
import pyautogui

# -----------------------------
# CONFIGURATION
# -----------------------------
remote_host = "REMOTE_HOST_IP"       # Replace with remote host IP
remote_user = "REMOTE_USER"          # Replace with remote username
remote_password = "REMOTE_PASSWORD"  # Replace with remote password
keypath = os.path.expanduser("~/.ssh/id_rsa")

# Folder for screenshots
os.makedirs("screenshots", exist_ok=True)

# -----------------------------
# HELPER FUNCTION TO TAKE SCREENSHOTS
# -----------------------------
def take_screenshot(filename):
    time.sleep(1)  # Wait for terminal to update
    screenshot_path = os.path.join("screenshots", filename)
    pyautogui.screenshot(screenshot_path)
    print(f"[+] Screenshot saved: {screenshot_path}")

# -----------------------------
# STEP 1: LOCAL SSH KEY GENERATION
# -----------------------------
print("[*] Generating SSH key on local host...")
subprocess.run(f"ssh-keygen -t rsa -b 4096 -f {keypath} -N ''", shell=True)
take_screenshot("local_ssh_keygen.png")

# -----------------------------
# STEP 2: CONNECT TO REMOTE HOST
# -----------------------------
print(f"[*] Connecting to remote host {remote_host}...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(remote_host, username=remote_user, password=remote_password)

# -----------------------------
# STEP 3: REMOTE SSH KEY GENERATION
# -----------------------------
print("[*] Generating SSH key on remote host...")
ssh.exec_command('ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""')
time.sleep(2)
take_screenshot("remote_ssh_keygen.png")

# -----------------------------
# STEP 4: SHOW KEYS
# -----------------------------
# Local public key
print("[*] Displaying local public key...")
subprocess.run(f"cat {keypath}.pub", shell=True)
take_screenshot("local_public_key.png")

# Remote authorized_keys
print("[*] Displaying remote authorized_keys...")
stdin, stdout, stderr = ssh.exec_command("cat ~/.ssh/authorized_keys")
print(stdout.read().decode())
take_screenshot("remote_authorized_keys.png")

# -----------------------------
# STEP 5: UPLOAD & RUN BRIDGE CONFIG SCRIPT
# -----------------------------
print("[*] Uploading bridge configuration script...")
sftp = ssh.open_sftp()
sftp.put("configure_bridge.sh", "/tmp/configure_bridge.sh")
sftp.close()

print("[*] Running bridge configuration script on remote host...")
ssh.exec_command("chmod +x /tmp/configure_bridge.sh && /tmp/configure_bridge.sh")
time.sleep(5)  # Wait for configuration to complete
take_screenshot("bridge_configuration.png")

# -----------------------------
# STEP 6: LOCAL PING TEST
# -----------------------------
print("[*] Testing connectivity from local host...")
subprocess.run("ping -c 1 192.168.30.1", shell=True)
take_screenshot("local_ping.png")

# -----------------------------
# STEP 7: DISPLAY REMOTE IPTABLES
# -----------------------------
print("[*] Displaying iptables on remote host...")
stdin, stdout, stderr = ssh.exec_command("sudo iptables -L -n -v")
print(stdout.read().decode())
take_screenshot("remote_iptables.png")

ssh.close()
print("[+] All steps completed. Screenshots saved in 'screenshots/' folder.")
