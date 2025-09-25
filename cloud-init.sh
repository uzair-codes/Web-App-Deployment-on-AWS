#!/bin/bash
#====================================
# Author: Uzair Shah
# Date:  September 25, 2025
# Purpose: Fully automate deployment of a web app (React portfolio) on EC2 instances 
#          launched by an Auto Scaling Group (ASG).
# How to use:
#  - Replace <GITHUB_USER> in GITHUB_REPO with your GitHub username or repo URL.
#  - Copy & paste this entire script into Launch Template → Advanced Details → User data.
#  - Update your Auto Scaling Group to use the new Launch Template version.
#  - Every new EC2 instance launched by the ASG will self-provision using this script
#    and automatically register as healthy behind your Application Load Balancer.
#===================================

set -xe  # Exit immediately if a command fails (-e), and print commands as they run (-x)

#---------------------------
# LOGGING SETUP
#---------------------------
LOGFILE=/var/log/user-data.log
exec > >(tee -a ${LOGFILE}) 2>&1
# Redirects all script output (stdout & stderr) to both console & log file.
# This is very helpful for debugging when something goes wrong — check /var/log/user-data.log.

#---------------------------
# SYSTEM UPDATE & ESSENTIALS
#---------------------------
apt update && apt upgrade -y  # Update package lists & upgrade existing packages

# Install common dependencies
apt install -y curl git build-essential ca-certificates

#---------------------------
# INSTALL NODE.JS (v18)
#---------------------------
# Download & run NodeSource setup script, then install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

#---------------------------
# INSTALL & ENABLE NGINX
#---------------------------
apt-get install -y nginx
systemctl enable nginx  # Make sure Nginx auto-starts on reboot

#---------------------------
# VARIABLES (CUSTOMIZE IF NEEDED)
#---------------------------
GITHUB_REPO="https://github.com/<GITHUB_USER>/personal-portfolio.git"  # <-- Change this
APP_DIR="/opt/personal-portfolio"  # Directory where app will be stored

#---------------------------
# CLONE APP REPOSITORY
#---------------------------
rm -rf ${APP_DIR}  # Remove old app directory (if exists) to avoid conflicts
git clone ${GITHUB_REPO} ${APP_DIR} || { echo "git clone failed"; exit 1; }
# Clone the GitHub repo. If cloning fails, stop the script (prevents broken deploys).

cd ${APP_DIR}

#---------------------------
# INSTALL DEPENDENCIES & BUILD
#---------------------------
npm install --production=false  # Install all dependencies (including dev)
npm run build  # Build production-optimized React static files

#---------------------------
# DEPLOY TO WEBROOT
#---------------------------
rm -rf /var/www/personal-portfolio
mkdir -p /var/www/personal-portfolio
cp -r build/* /var/www/personal-portfolio
chown -R www-data:www-data /var/www/personal-portfolio  # Set correct permissions for Nginx

#---------------------------
# NGINX CONFIGURATION
#---------------------------
# Replace default config with a custom one to serve React app
cat > /etc/nginx/sites-available/personal-portfolio <<'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/personal-portfolio;
    index index.html;

    # React apps require serving index.html for unknown routes (SPA fallback)
    location / {
        try_files $uri /index.html;
    }

    # Cache static assets for better performance
    location ~* \.(?:css|js|jpg|jpeg|gif|png|svg|ico|woff2?|ttf)$ {
        expires 30d;
        add_header Cache-Control "public, must-revalidate";
    }
}
EOF

# Enable new site config & disable default one
ln -fs /etc/nginx/sites-available/personal-portfolio /etc/nginx/sites-enabled/personal-portfolio
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration & reload service
nginx -t && systemctl restart nginx

#---------------------------
# FINAL LOG
#---------------------------
echo "Deployment finished successfully at $(date)" >> ${LOGFILE}
