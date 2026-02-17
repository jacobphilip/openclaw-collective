#!/bin/bash
USER_IP=$1
ssh $USER_IP 'sudo apt update && sudo apt install -y nodejs git curl'
ssh $USER_IP 'curl -fsSL https://openclaw.ai/install.sh | bash'
ssh $USER_IP 'openclaw config set defaultAgent archivist'
# Add Ollama, models rsync, etc. – expand as needed
