#!/bin/bash
#
##############################################
#                                             #
#Name: Dare Ayoola                            #
#Script Name: create_user                     #
#Function:                                    #
#                                             #
#                                             #
################################################

# Check if input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi
INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create log file and password file directories if they don't exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PASSWORD_FILE")"

# Ensure password file permissions are secure
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Function to generate random password
generate_password() {
  openssl rand -base64 12
}

# Function to log messages
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Read and process the input file
while IFS=';' read -r username groups; do
  
#Trim whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

#Create user and primary group
  if id "$username" &>/dev/null; then
    log_message "User $username already exists"
  else
    useradd -m -G "$username" -s /bin/bash "$username"
    log_message "User $username created"
    
#Generate and set password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_message "Password for $username set"
  
 #Create additional groups
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
      group=$(echo "$group" | xargs)
      if ! getent group "$group" &>/dev/null; then
        groupadd "$group"
        log_message "Group $group created"
      fi
      usermod -aG "$group" "$username"
      log_message "User $username added to group $group"
    done
  fi
done < "$INPUT_FILE"
log_message "User creation process completed"
echo "Script execution completed. Check $LOG_FILE for details."
