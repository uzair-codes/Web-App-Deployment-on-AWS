#🌐 AWS 2-Tier VPC Project with ALB, NAT Gateway & Bastion Host

````markdown
A step-by-step AWS project to build a "secure, production-like environment" using a two-tier VPC architecture with public
& private subnets, NAT Gateway, Application Load Balancer, Auto Scaling Group, and a Bastion Host.  
We deploy a "simple Python web app on port 3000" inside private subnets and serve it through the ALB.
````


✨ Key Features
````markdown
- 🏗 "Custom VPC" with 2 public + 2 private subnets across 2 Availability Zones  
- 🌐 "Internet Gateway" for public access  
- 🔑 "NAT Gateway" for secure internet access from private subnets  
- 🖥 "Auto Scaling Group" running EC2 instances in private subnets  
- 🛡 "Bastion Host" for secure SSH access to private instances  
- ⚖ "Application Load Balancer" for distributing traffic across EC2 instances  
- 🐍 "Python Web Server" running a sample app on port 3000  
````

📋 Prerequisites
````markdown
Before you start, make sure you have:

- ✅ "AWS Free-Tier Account"
- ✅ Basic "Linux command-line" knowledge
- ✅ Installed:
  - SSH client (e.g., OpenSSH)
  - Git (optional, for version control)
````


####🚀 Step-by-Step Setup Guide

 1️⃣ Create VPC & Subnets
````markdown
1. Go to "AWS Console" → Search ""VPC""
2. Click "Create VPC" → Choose "VPC and more"
3. Configure:
   - Name: `aws-web-app-vpc`
   - Availability Zones: `2`
   - Public subnets: `2`
   - Private subnets: `2`
   - NAT Gateways: `1 per AZ`
   - VPC Endpoints: `None`
4. Click "Create VPC"  
AWS will create:
- VPC  
- 2 public + 2 private subnets  
- Internet Gateway (attached)  
- Route Tables (associated with subnets)  
- NAT Gateway with Elastic IP

> ⚠ "Troubleshooting:"  
> If you hit *Max Elastic IPs reached*, go to "EC2 → Elastic IPs" → Release unused ones → Retry VPC creation.
````


 2️⃣ Launch Bastion Host (Jump Server)
````markdown
1. Go to "EC2 → Launch Instance"
2. Configure:
   - Name: `Bastion-Host`
   - AMI: `Ubuntu 22.04 LTS`
   - Type: `t3.micro`
   - Key-pair: `Choose an existing key or create one (download my-key.pem file).`
   - VPC: `aws-web-app-vpc`
   - Subnet: "Public subnet"
   - Auto-assign Public IP: "Enabled"
3. Create Security Group:
   - Allow "SSH (22)" from *your IP only*
4. Launch instance and download `.pem` key if not already done.
````


 3️⃣ Create Auto Scaling Group (ASG)
````markdown
1. Go to "EC2 → ASG → Launch Templates → Create"
   - Name: `aws-web-app-asg-launch-temp`
   - AMI: Ubuntu 22.04
   - Instance type: `t3.micro`
   - VPC: `aws-web-app-vpc`
   - Security Group rules:
     - Allow "SSH (22)" from Bastion Host SG
     - Allow "TCP (3000)" & "HTTP (80)" from Load Balancer SG
2. Go to "EC2 → Auto Scaling Groups → Create"
   - Select the launch template created above
   - VPC: `aws-web-app-vpc`
   - Select "private subnets"
   - Desired capacity: `2` (min: `2`, max: `4`)
   - Skip load balancer (we'll add it later)
````

 4️⃣ SSH & Deploy App

 SSH to Bastion Host
```bash
ssh -i my-key.pem ubuntu@<BASTION_PUBLIC_IP>
```

 Copy PEM to Bastion (for private SSH)

```bash
scp -i my-key.pem my-key.pem ubuntu@<BASTION_PUBLIC_IP>:~
```

 SSH into Private Instance

```bash
ssh -i my-key.pem ubuntu@<PRIVATE_INSTANCE_IP>
```

 Install Python & Run Simple Web App

```bash
sudo apt update && sudo apt install -y python3
echo "<h1>My First AWS Project</h1>" > index.html
python3 -m http.server 3000
```

> ✅ This starts a Python HTTP server on port `3000` inside the private instance.



 5️⃣ Create Target Group & ALB
````markdown
1. Go to "EC2 → Target Groups → Create"

   * Target type: `Instances`
   * Protocol: `HTTP`
   * Port: `3000`
   * VPC: `aws-web-app-vpc`
   * Register both private EC2 instances
2. Go to "Load Balancers → Create Load Balancer → Application Load Balancer"

   * Name: `aws-web-app-ALB`
   * Internet-facing
   * Select both "public subnets"
   * Create Security Group: allow "HTTP (80)" from anywhere
   * Attach target group created above
3. Wait until ALB status = "Active"
````


 6️⃣ Test the Setup
````markdown
* Copy "ALB DNS Name" → open in browser
* You should see the app running
* Stop one EC2 instance in ASG → refresh → ALB still serves from healthy instance
````


 🔧 Troubleshooting

| Issue                               | Solution                                                                      |
| -- | -- |
| "Load Balancer shows 503/Timeout" | Check Target Group health checks, ensure port 3000 is open and app is running |
| "Cannot SSH to private instance"  | Ensure Bastion Host is in same VPC and SG allows SSH from Bastion SG          |
| "NAT Gateway not working"         | Check if Elastic IP is attached and private route table points to NAT Gateway |
| "Health checks failing"           | Make sure app is listening on correct port (3000) and SG allows ALB access    |
| "ALB unreachable"                 | Open port 80 in ALB Security Group                                            |



 🎯 Learning Outcomes

By completing this project, you will learn:

* How to design a "secure 2-tier AWS network architecture"
* How to use "VPC, subnets, route tables, NAT Gateway, IGW"
* How to deploy scalable apps with "Auto Scaling Groups"
* How to expose private apps securely using "Application Load Balancer"
* How to securely access private resources with a "Bastion Host"
* How to troubleshoot networking & connectivity issues in AWS



 📝 License

This project is released under the "MIT License" — feel free to use, modify, and share.



 🙌 Credits

This project was created as part of a hands-on AWS learning journey.
Thanks to AWS documentation & tutorials for guidance.

