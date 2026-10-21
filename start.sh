#!/bin/bash
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

CFG_FILE="/contract/cfg/hp.cfg"
SSHD_CONFIG="/etc/ssh/sshd_config"
PORT_FLAG="/etc/ssh/.custom_port_done"
if [ ! -f "$PORT_FLAG" ]; then
    echo "First boot detected. Configuring SSH port..."
    userport=$(awk '
      $0 ~ /"user"/ { user_block=1 }
      user_block && $0 ~ /"port"/ {
        gsub(/[ ,]/, "", $2)
        gsub(/[^0-9]/, "", $2)
        print $2
        exit
      }
    ' "$CFG_FILE")

    if [[ -z "$userport" ]]; then
      echo "Could not extract port from $CFG_FILE"
      exit 1
    fi

    if ! grep -E -q "^[[:space:]]*Port[[:space:]]+$userport(\b|$)" "$SSHD_CONFIG"; then
      echo "Adding Port $userport to $SSHD_CONFIG"
      echo "Port $userport" >> "$SSHD_CONFIG"
    else
      echo "Port $userport already exists in $SSHD_CONFIG"
    fi

    touch "$PORT_FLAG"
    echo "SSH port configuration done and will not run again."

else
    echo "SSH port setup already completed. Skipping."
fi

check_service() {
    local service_name="$1"
    local start_command="$2"

    if ! pgrep -f "$service_name" > /dev/null; then
        echo "$service_name is not running. Restarting..."

        nohup bash -c "$start_command" > /dev/null 2>&1 &

        echo "$service_name restarted."
    else
        echo "$service_name is running."
    fi
}

while true; do
    check_service "supervisord" "/usr/bin/supervisord -c /home/everbackup/supervisord.conf"
    sleep 10
done
