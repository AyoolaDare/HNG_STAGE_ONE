#!/bin/bash

# Constants
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# create password file and set permissions
sudo mkdir -p $(dirname "$PASSWORD_FILE")
sudo touch $PASSWORD_FILE
sudo chown $USER:$USER $PASSWORD_FILE
sudo chmod 600 $PASSWORD_FILE

# Function to create a user and group
create_user_and_groups() {
  local username=$1
  local groups=$2

  # Create users with primary group same as username
  sudo groupadd $username >> $LOG_FILE 2>&1
  sudo useradd -m -g $username $username >> $LOG_FILE 2>&1

  # Create additional groups if specified
  IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do
    sudo groupadd $group >> $LOG_FILE 2>&1
    sudo usermod -aG $group $username >> $LOG_FILE 2>&1
  done

  # Generate random passwords for each user
  password=$(openssl rand -base64 12)
  echo "$username:$password" >> $PASSWORD_FILE

  # Set password for user
  echo "$username:$password" | sudo chpasswd >> $LOG_FILE 2>&1

  # Log action
  echo "$(date): Created user '$username' with groups '$groups'" >> $LOG_FILE
}

# script execution starts from here
input_file=$1

# Read the input txt file to create users
while IFS=';' read -r username groups; do
  # remove whitespaces
  username=$(echo $username | tr -d '[:space:]')
  groups=$(echo $groups | tr -d '[:space:]')

  # Check if user already exists
  if id "$username" &>/dev/null; then
    echo "User '$username' already exists. Skipping."
    echo "$(date): User '$username' creation skipped (user already exists)" >> $LOG_FILE
  else
    # Call function to create user and groups
    create_user_and_groups "$username" "$groups"
  fi
done < "$input_file"
