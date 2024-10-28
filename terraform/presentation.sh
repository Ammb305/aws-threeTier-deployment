#!/bin/bash
# Update package list and install required packages
sudo yum update -y
sudo yum install -y git

# Install Node.js (use NodeSource for the latest version)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install NGINX
sudo yum install -y nginx

# Start and enable NGINX
sudo systemctl start nginx
sudo systemctl enable nginx

# Define variables
REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git"
BRANCH_NAME="feature/add-logging"
REPO_DIR="/home/ec2-user/aws-threeTier-deployment/frontend"
ENV_FILE="$REPO_DIR/.env"
APP_TIER_ALB_URL="http://internal-application-loadBalancer-1072175246.us-east-1.elb.amazonaws.com"  # Replace with your actual alb endpoint
API_URL="/api"

# Clone the repository as ec2-user
cd /home/ec2-user
sudo -u ec2-user git clone $REPO_URL
cd aws-threeTier-deployment

# Checkout to the specific branch
sudo -u ec2-user git checkout $BRANCH_NAME
cd frontend

# Ensure ec2-user owns the directory
sudo chown -R ec2-user:ec2-user /home/ec2-user/aws-threeTier-deployment

# Create .env file with the API_URL
echo "VITE_API_URL=\"$API_URL\"" >> "$ENV_FILE"

# Install Node.js dependencies as ec2-user
sudo -u ec2-user npm install

# Build the frontend application as ec2-user
sudo -u ec2-user npm run build

# Copy the build files to the NGINX directory
sudo cp -r dist /usr/share/nginx/html/

# Update NGINX configuration
NGINX_CONF="/etc/nginx/nginx.conf"
SERVER_NAME="<learningdevops.site www.learningdevops.site>"  # Replace with your actual domain name

# Backup existing NGINX configuration
sudo cp $NGINX_CONF ${NGINX_CONF}.bak

# Write new NGINX configuration
sudo tee $NGINX_CONF > /dev/null <<EOL
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create a separate NGINX configuration file
sudo tee /etc/nginx/conf.d/presentation-tier.conf > /dev/null <<EOL
server {
    listen 80;
    server_name $SERVER_NAME;
    root /usr/share/nginx/html/dist;
    index index.html index.htm;

    #health check
    location /health {
        default_type text/html;
        return 200 "<!DOCTYPE html><p>Health check endpoint</p>\n";
    }

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass $APP_TIER_ALB_URL;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL


# Restart NGINX to apply the new configuration
sudo systemctl restart nginx






# --------------

# #!/bin/bash
# set -e  # Exit immediately if a command exits with a non-zero status.

# # Update package list and install required packages
# sudo apt update -y
# sudo apt install -y git curl nginx

# # Install Node.js (use NodeSource for the latest version)
# curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# sudo apt install -y nodejs

# # Start and enable NGINX
# sudo systemctl start nginx
# sudo systemctl enable nginx

# # Define variables
# REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git"
# BRANCH_NAME="main"
# REPO_DIR="/home/ubuntu/aws-threeTier-deployment/frontend"
# ENV_FILE="$REPO_DIR/.env"
# APP_TIER_ALB_URL="http://internal-application-loadBalancer-1957214653.us-east-1.elb.amazonaws.com"  # Replace with your actual ALB endpoint
# API_URL="/api"
# SERVER_NAME="learningdevops.site www.learningdevops.site"

# # Clone the repository as ubuntu user
# cd /home/ubuntu
# sudo -u ubuntu git clone $REPO_URL
# cd aws-threeTier-deployment

# # Checkout to the specific branch
# sudo -u ubuntu git checkout $BRANCH_NAME
# cd frontend

# # Ensure ubuntu user owns the directory
# sudo chown -R ubuntu:ubuntu /home/ubuntu/aws-threeTier-deployment

# # Create .env file with the API_URL
# echo "VITE_API_URL=\"$API_URL\"" >> "$ENV_FILE"

# # Install Node.js dependencies as ubuntu user
# sudo -u ubuntu npm install

# # Build the frontend application as ubuntu user
# sudo -u ubuntu npm run build

# # Copy the build files to the NGINX directory
# sudo cp -r dist/* /usr/share/nginx/html/

# # Update NGINX configuration
# NGINX_CONF="/etc/nginx/nginx.conf"

# # Backup existing NGINX configuration
# sudo cp $NGINX_CONF ${NGINX_CONF}.bak

# # Write new NGINX configuration
# sudo tee $NGINX_CONF > /dev/null <<EOL
# user www-data;
# worker_processes auto;

# error_log /var/log/nginx/error.log warn;
# pid /run/nginx.pid;

# events {
#     worker_connections 1024;
# }

# http {
#     include /etc/nginx/mime.types;
#     default_type application/octet-stream;

#     log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
#                     '\$status \$body_bytes_sent "\$http_referer" '
#                     '"\$http_user_agent" "\$http_x_forwarded_for"';

#     access_log /var/log/nginx/access.log main;

#     sendfile on;
#     tcp_nopush on;
#     tcp_nodelay on;
#     keepalive_timeout 65;
#     types_hash_max_size 2048;

#     include /etc/nginx/conf.d/*.conf;
# }
# EOL

# # Create a separate NGINX configuration file
# sudo tee /etc/nginx/conf.d/presentation-tier.conf > /dev/null <<EOL
# server {
#     listen 80;
#     server_name $SERVER_NAME;
#     root /usr/share/nginx/html;
#     index index.html index.htm;

#     # Health check
#     location /health {
#         default_type text/html;
#         return 200 "<!DOCTYPE html><p>Health check endpoint</p>\n";
#     }

#     location / {
#         try_files \$uri /index.html;
#     }

#     location /api/ {
#         proxy_pass $APP_TIER_ALB_URL;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#     }
# }
# EOL

# # Restart NGINX to apply the new configuration
# sudo systemctl restart nginx

# # Output success message
# echo "Deployment completed successfully!"
