#!/bin/bash

set -e

echo "=========================================="
echo " Jenkins Installation - Ubuntu 22.04"
echo "=========================================="

# --------------------------------------------------
# Step 0: Check OS
# --------------------------------------------------

echo "[0/7] Checking operating system..."

if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    echo "WARNING: This script was designed for Ubuntu 22.04"
fi

echo "OS check completed."


# --------------------------------------------------
# Step 1: Remove old/manual Jenkins installation
# --------------------------------------------------

echo "[1/7] Cleaning previous Jenkins installation..."

sudo systemctl stop jenkins 2>/dev/null || true
sudo systemctl disable jenkins 2>/dev/null || true

sudo rm -f /etc/systemd/system/jenkins.service

sudo rm -f /etc/apt/sources.list.d/jenkins.list

sudo rm -f /etc/apt/keyrings/jenkins.gpg
sudo rm -f /etc/apt/keyrings/jenkins-keyring.asc
sudo rm -f /etc/apt/keyrings/jenkins-keyring.gpg

sudo systemctl daemon-reload

echo "Cleanup completed."


# --------------------------------------------------
# Step 2: Install Java 21
# --------------------------------------------------

echo "[2/7] Installing Java 21..."

sudo apt-get update

sudo apt-get install -y \
    fontconfig \
    openjdk-21-jre

echo ""
echo "Java version:"
java --version
echo ""


# --------------------------------------------------
# Step 3: Add Jenkins repository
# --------------------------------------------------

echo "[3/7] Adding Jenkins repository..."

sudo mkdir -p /etc/apt/keyrings

sudo curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update

echo "Jenkins repository added."


# --------------------------------------------------
# Step 4: Install Jenkins
# --------------------------------------------------

echo "[4/7] Installing Jenkins..."

sudo apt-get install -y jenkins

echo "Jenkins package installed."


# --------------------------------------------------
# Step 5: Enable and start Jenkins
# --------------------------------------------------

echo "[5/7] Starting Jenkins..."

sudo systemctl enable jenkins
sudo systemctl start jenkins

sleep 10

echo ""
echo "Jenkins service status:"
sudo systemctl status jenkins --no-pager

echo ""


# --------------------------------------------------
# Step 6: Verify Jenkins
# --------------------------------------------------

echo "[6/7] Verifying Jenkins..."

if sudo systemctl is-active --quiet jenkins; then
    echo "SUCCESS: Jenkins is running."
else
    echo "ERROR: Jenkins failed to start."
    echo ""
    echo "Check logs using:"
    echo "sudo journalctl -u jenkins -n 100 --no-pager"
    exit 1
fi

echo ""

echo "Checking Jenkins port..."

if sudo ss -lntp | grep -q ":8080"; then
    echo "SUCCESS: Jenkins is listening on port 8080."
else
    echo "WARNING: Jenkins is not listening on port 8080."
fi


# --------------------------------------------------
# Step 7: Display information
# --------------------------------------------------

echo ""
echo "=========================================="
echo " Jenkins Installation Completed"
echo "=========================================="

echo ""
echo "Java:"
java --version

echo ""
echo "Jenkins Service:"
sudo systemctl is-active jenkins

echo ""
echo "Jenkins Port:"
sudo ss -lntp | grep 8080 || true

echo ""
echo "Jenkins Initial Admin Password:"
echo "------------------------------------------"

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Password file not available yet."
    echo "Try:"
    echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

echo ""
echo "=========================================="
echo " Jenkins URL"
echo "=========================================="

PUBLIC_IP=$(curl -s --max-time 5 \
    http://169.254.169.254/latest/meta-data/public-ipv4 || true)

if [ -n "$PUBLIC_IP" ]; then
    echo "http://${PUBLIC_IP}:8080"
else
    echo "Could not determine EC2 public IP."
    echo "Use your EC2 Public IPv4 address:"
    echo "http://<EC2-PUBLIC-IP>:8080"
fi

echo ""
echo "=========================================="
echo " Installation Finished"
echo "=========================================="