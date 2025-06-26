#!/bin/bash

# Enable error handling
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Update SSH password if provided
if [ ! -z "$SSH_PASSWORD" ]; then
    echo "developer:$SSH_PASSWORD" | chpasswd
    log "SSH password updated"
fi

# Update VNC password if provided
if [ ! -z "$VNC_PASSWORD" ]; then
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/developer/.vnc/passwd
    chown developer:developer /home/developer/.vnc/passwd
    chmod 600 /home/developer/.vnc/passwd
    log "VNC password updated"
fi

# Ensure proper permissions on workspace
chown -R developer:developer /home/developer/workspace || true

# Start SSH service
log "Starting SSH service..."
service ssh start

# Start KasmVNC (already configured in base image)
log "Starting KasmVNC..."
su - developer -c '/opt/kasm/bin/kasm_default_profile.sh' &

# Configure Git globally for the developer user
su - developer -c "git config --global --add safe.directory /home/developer/workspace" || true

# Create a welcome script for developer
cat > /home/developer/welcome.sh << 'EOF'
#!/bin/bash
echo "================================================="
echo "Welcome to VS Code Rails Development Environment!"
echo "================================================="
echo ""
echo "Access methods:"
echo "  - SSH: ssh developer@localhost -p 2222"
echo "  - Web Desktop: https://localhost:6901"
echo "  - Rails: http://localhost:3000"
echo ""
echo "Default credentials:"
echo "  - Username: developer"
echo "  - Password: developer"
echo ""
echo "Installed tools:"
echo "  - Ruby: $(ruby -v | cut -d' ' -f2)"
echo "  - Rails: $(rails -v | cut -d' ' -f2)"
echo "  - Node.js: $(node -v)"
echo "  - VS Code: $(code --version | head -1)"
echo ""
echo "Happy coding!"
echo "================================================="
EOF

chmod +x /home/developer/welcome.sh
chown developer:developer /home/developer/welcome.sh

# Add welcome script to bashrc
grep -q "welcome.sh" /home/developer/.bashrc || echo "/home/developer/welcome.sh" >> /home/developer/.bashrc

# Keep container running
log "All services started. Container is ready!"
tail -f /dev/null