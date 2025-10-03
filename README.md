# 🚀 Web App Deployment on AWS

This project demonstrates how to build and deploy a **highly available, secure web application on AWS** using a **2-tier VPC architecture**. It is divided into **two main parts**:

1. **Infrastructure Creation** — Setting up the AWS environment (VPC, subnets, NAT Gateway, Bastion Host, ALB, Auto Scaling Group).
2. **Application Deployment** — Deploying a React/Node.js based portfolio web app inside the private subnets and serving it through the ALB.

The combination of these two parts creates a **production-like environment** for hosting modern web applications.

---

## 📂 Repository Structure

* **[`AWS_VPC_Creation.md`](./AWS_VPC_Creation.md)**
  Step-by-step guide for setting up the AWS network infrastructure manually via AWS Console.

  * Creates **VPC with 2 public + 2 private subnets** across AZs
  * Configures **NAT Gateway, Bastion Host, Auto Scaling Group, and ALB**
  * Ensures private EC2 instances are securely accessible and traffic is served via ALB

* **[`WEB_APP_DEPLOYMENT.md`](./WEB_APP_DEPLOYMENT.md)**
  Guide for deploying the actual **portfolio web app** on the infrastructure created above.

  * Manual deployment via Bastion Host (quick test setup)
  * Automated deployment using **cloud-init/user-data scripts** (recommended for Auto Scaling)
  * Uses **Nginx** to serve the static React build in a production-ready way

---

## 🏗 Project Workflow

1. **Set up infrastructure**
   Follow [`AWS_VPC_Creation.md`](./AWS_VPC_Creation.md) to build the secure 2-tier VPC and related components.

2. **Deploy the app**
   Once infra is ready, follow [`WEB_APP_DEPLOYMENT.md`](./WEB_APP_DEPLOYMENT.md) to deploy and serve the portfolio application inside the private EC2 instances.

---

## ✨ Key Highlights

* ✅ **2-tier architecture** (public + private subnets across 2 AZs)
* ✅ **Scalable and fault-tolerant** with Auto Scaling Group + ALB
* ✅ **Secure private app hosting** via NAT + Bastion Host
* ✅ **Production-ready app serving** with Nginx and React build
* ✅ **Automation friendly** (cloud-init ensures ASG replacements stay consistent)

---

## 📋 Prerequisites

* AWS Free-Tier or paid account
* Basic Linux command-line knowledge
* Installed: SSH client, Git, AWS CLI (optional)
* Portfolio code → [personal-portfolio](https://github.com/uzair-codes/personal-portfolio)

---

## 🎯 Learning Outcomes

By completing this project, you will learn how to:

* Design and build a **secure AWS VPC architecture**
* Deploy applications inside **private subnets with public access via ALB**
* Use **Bastion Hosts for secure access**
* Automate deployments with **cloud-init & Auto Scaling Groups**
* Serve React apps with **Nginx in production**

---

## 📝 License

This project is licensed under the **MIT License** — feel free to use, modify, and share.

---

🙌 **Credits**: AWS official docs & community tutorials for guidance.

---

👉 This general `README.md` introduces the project and tells readers which `.md` file to follow depending on their step.
