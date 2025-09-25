# Highly Available abs Secure Web App Deployment on AWS
## Feel free to clone or download my portfolio code from [personal-portfolio](https://github.com/uzair-codes/personal-portfolio)
Check it out live 👉 [[https://syed-uzair-shah.vercel.app](https://syed-uzair-shah.vercel.app/)]

```
There are two ways we can achieve this, pick whichever fits:
 - Manual / one-time (SSH via Bastion) — quick, good for testing.
 - Automated (recommended) — cloud-init / user-data in your Launch Template — required if
Auto Scaling may replace instances (keeps instances identical and self-provisioning).
```
## Prerequisites & assumptions (check before starting)
Please refer to **AWS_VPC_CREATION.md** 
```
 - You already created the VPC, 2 private subnets, 2 public subnets, NAT gateway and a Bastion host (or will).
The bastion allows SSH into private instances. (Your project doc covers this flow). 
 - You have a key pair (.pem) you can use from your laptop and you copied it to the bastion (or can SSH through agent forwarding). 
 - Two EC2 instances (Ubuntu 22.04 / 20.04 recommended) exist in the private subnets (either created by ASG or manually).
If they’re in an ASG, you’ll want an automated approach (user-data). 
 - You have (or will create) a Target Group + ALB that routes traffic to your instances.
Decide whether the ALB target port is 80 or 3000. (I’ll show both options below.)
```
## Recommended choice (short): Use Nginx to serve the static React build
Why: CRA npm run build produces a static site. Nginx is lightweight, fast, production-ready and works well with ALB. We’ll:
```
 - Build the app (npm run build) on each instance (or build once then copy).
 - Serve the build/ folder with Nginx on port 80 (or 3000 if you prefer to keep your existing ALB target group port).
 - Make this automatic with cloud-init (recommended for ASG).
```
# Option A - Manual deployment (quick test, step-by-step)
Use this if you want to quickly validate the site on the two instances.

## 1) SSH to Bastion, then to private instance
(from your laptop)

### Copy key to bastion (if not already)
```bash
scp -i ~/keys/mykey.pem ~/keys/mykey.pem ubuntu@<BASTION_PUBLIC_IP>:~/
```
### SSH to bastion
```bash
ssh -i ~/keys/mykey.pem ubuntu@<BASTION_PUBLIC_IP>
```
### From bastion SSH into a private EC2 instance
```bash
ssh -i ~/mykey.pem ubuntu@<PRIVATE_INSTANCE_IP>
```
(If you already copied the PEM to the bastion, just SSH from bastion to private IP.)

## 2) Install system packages, Node.js, Git, and Nginx (on the private instance)
Run as ubuntu (sudo will be used):
#### update
```bash
sudo apt update && sudo apt upgrade -y
```
#### install common tools
```bash
sudo apt install -y curl git build-essential
```
#### install Node 18 LTS (NodeSource)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```
#### confirm
```bash
node -v && npm -v
```
#### install nginx
```bash
sudo apt install -y nginx
sudo systemctl enable --now nginx
```

## 3) Clone your repo and build the static site
Replace <GITHUB_USER> if needed. If your repo is public use HTTPS; if private, use SSH key or a token.
```bash
cd /home/ubuntu
git clone https://github.com/<GITHUB_USER>/personal-portfolio.git
cd personal-portfolio
```
#### install dependencies (use npm ci if package-lock.json exists)
```bash
npm install      # or: npm ci
```
#### start development server
```bash
npm start  # Runs the app locally in development mode (with hot reload).  
```
#### build production static files
```bash
npm run build
```
#### build output appears in ./build

## 4) Configure Nginx to serve build/
### __*Option 1:*__ Serve on port 80 (recommended)
#### backup default
```bash
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
```
#### create new site config
```bash
sudo tee /etc/nginx/sites-available/personal-portfolio <<'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/personal-portfolio;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    # serve static files aggressively
    location ~* \.(?:css|js|jpg|jpeg|gif|png|svg|ico|woff2?|ttf)$ {
        expires 30d;
        add_header Cache-Control "public, must-revalidate";
    }
}
EOF
```
#### create webroot and copy build files
```bash
sudo rm -rf /var/www/personal-portfolio
sudo mkdir -p /var/www/personal-portfolio
sudo cp -r build/* /var/www/personal-portfolio/
sudo chown -R www-data:www-data /var/www/personal-portfolio
```
#### enable site and reload nginx
```bash
sudo ln -s /etc/nginx/sites-available/personal-portfolio /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```
## __*Option 2:*__ If your ALB target group uses port 3000 already, change listen 80 to listen 3000 in the site config and 
ensure the instance SG allows inbound from ALB SG on 3000.

## 5) Validate locally (from the instance) and via ALB

#### From the instance
```bash
curl -I http://localhost/        # should return HTTP/1.1 200 OK
```
#### From bastion (SSH forwarded) or ALB's health check
```bash
curl -I http://<PRIVATE_INSTANCE_IP>/ 
```
Then open your ALB DNS in browser — it should show the site. If you served on 3000, either browse ALB DNS (listener) or 
adjust ALB target group to port 3000.

## 6) Repeat on the second EC2 instance
Either repeat steps 1–5 on the second instance manually or copy /var/www/personal-portfolio from the first instance (rsync/scp). 
But note: if instances are part of an Auto Scaling Group, manual changes will be lost when ASG replaces an instance → use automation (next section).

---

# OPTION B — Automated (recommended for Auto Scaling / long term)
*When deploying a web app on AWS with EC2 instances running in an Auto Scaling Group (ASG), you can fully 
automate the setup of each instance using user-data (powered by cloud-init). User-data is simply a script 
that runs automatically when a new instance launches. You add this script in your Launch Template under 
Advanced Details → User data (or as --user-data when creating instances with the CLI). This allows every 
new EC2 instance created by the ASG to self-provision on boot — for example, it can update packages, install 
dependencies, clone your web app’s repository, and start your application on the correct port. This approach 
removes the need to SSH into each instance manually, ensures all instances are configured exactly the same way, 
and keeps your infrastructure consistent even when new instances are launched during scaling events.*
```
This script:
  - Installs Node 18 and Nginx
  - Clones the GitHub repo
  - Runs npm ci and npm run build
  - Deploys the build to Nginx and starts nginx
  - Sends simple logs to /var/log/user-data.log
```

