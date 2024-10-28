# #!/bin/bash
# # Update package list and install required packages
# sudo apt update -y
# sudo apt install -y git curl

# # Install Node.js (use NodeSource for the latest version)
# curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# sudo apt install -y nodejs

# # Install PM2 globally
# sudo npm install -g pm2

# # Define variables
# REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git"
# BRANCH_NAME="main"
# REPO_DIR="/home/ubuntu/react-node-mysql-app/backend"
# ENV_FILE="$REPO_DIR/.env"

# # Clone the repository
# cd /home/ubuntu
# sudo -u ubuntu git clone $REPO_URL
# cd react-node-mysql-app

# # Checkout to the specific branch
# sudo -u ubuntu git checkout $BRANCH_NAME
# cd backend

# # Define the log directory and ensure it exists
# LOG_DIR="/home/ubuntu/react-node-mysql-app/backend/logs"
# mkdir -p $LOG_DIR
# sudo chown -R ubuntu:ubuntu $LOG_DIR

# # Append environment variables to the .env file
# echo "LOG_DIR=$LOG_DIR" >> "$ENV_FILE"
# echo "DB_HOST=\"terraform-20241027185710975700000001.c5g22ewq4ztf.us-east-1.rds.amazonaws.com\"" >> "$ENV_FILE"
# echo "DB_PORT=\"3306\"" >> "$ENV_FILE"
# echo "DB_USER=\"admin\"" >> "$ENV_FILE"
# echo "DB_PASSWORD=\"admin123\"" >> "$ENV_FILE"  # Replace with actual password
# echo "DB_NAME=\"MySQLdatabase\"" >> "$ENV_FILE"

# # Install Node.js dependencies as ubuntu user
# sudo -u ubuntu npm install

# # Start the application using PM2 as ubuntu user
# sudo -u ubuntu npm run serve

# # Ensure PM2 restarts on reboot as ubuntu user
# sudo -u ubuntu pm2 startup systemd
# sudo -u ubuntu pm2 save


#!/bin/bash 

# Update package list and install required packages 
sudo yum update -y 
sudo yum install -y git 

# Install Node.js (use NodeSource for the latest version) 
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - 
sudo yum install -y nodejs 

# Install PM2 globally 
sudo npm install -g pm2 

# Define variables 
REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git" 
BRANCH_NAME="main" 
REPO_DIR="/home/ec2-user/aws-threeTier-deployment/backend" 
ENV_FILE="$REPO_DIR/.env" 

# Clone the repository 
cd /home/ec2-user 
git clone $REPO_URL 
cd aws-threeTier-deployment

# Checkout to the specific branch 
git checkout $BRANCH_NAME 
cd backend 

# Define the log directory and ensure it exists 
LOG_DIR="/home/ec2-user/aws-threeTier-deployment/backend/logs" 
mkdir -p $LOG_DIR 
sudo chown -R ec2-user:ec2-user $LOG_DIR

# Append environment variables to the .env file
echo "LOG_DIR=$LOG_DIR" >> "$ENV_FILE"
echo "DB_HOST=\"terraform-20241027185710975700000001.c5g22ewq4ztf.us-east-1.rds.amazonaws.com\"" >> "$ENV_FILE"
echo "DB_PORT=\"3306\"" >> "$ENV_FILE"
echo "DB_USER=\"admin\"" >> "$ENV_FILE"
echo "DB_PASSWORD=\"admin123\"" >> "$ENV_FILE"  # Replace with actual password
echo "DB_NAME=\"MySQLdatabase\"" >> "$ENV_FILE"

# Install Node.js dependencies as ec2-user
npm install

# Start the application using PM2 as ec2-user
pm2 start server.js --name "my-app" # Make sure you specify the correct entry file

# Ensure PM2 restarts on reboot
pm2 startup systemd 
pm2 save
