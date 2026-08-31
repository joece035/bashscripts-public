#!/bin/bash
ssh_setup() {
  local t=$1
      case $t in
          gen)
             local comment=${2:-}
              mkdir -p "$HOME/.ssh"
              ssh-keygen -t ed25519 -C 
              "$comment" &&
               cat ~/.ssh/id_ed25519.pub
               ;;
          add)
              local key=${2:-}
              mkdir -p ~/.ssh
              echo "$key" >> ~/.ssh/authorized_keys &&
              chmod 700 ~/.ssh &&
              chmod 600 ~/.ssh/authorized_keys &&
              echo "DONE ADDING PUBKEY"
              ;;
          *)
              echo "unknown agrument" && return 1
              ;;
      esac      
  }

ll(){
	local tar=${1:-$PWD}
	find "$tar" -type f \
			-type d \
			-
			
}
