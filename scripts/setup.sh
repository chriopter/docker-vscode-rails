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
    su - developer -c "echo '$VNC_PASSWORD' | vncpasswd -f > /home/developer/.vnc/passwd"
    su - developer -c "chmod 600 /home/developer/.vnc/passwd"
    log "VNC password updated"
fi

# Ensure proper permissions on workspace
chown -R developer:developer /home/developer/workspace || true

# Start SSH service
log "Starting SSH service..."
service ssh start

# Start VNC server as developer user with dynamic resolution support
log "Starting VNC server..."
su - developer -c "vncserver :1 -depth 24 -localhost no -xstartup /usr/bin/startxfce4" || true

# Start noVNC web server
log "Starting noVNC..."
su - developer -c "websockify --web=/usr/share/novnc/ --cert=/home/developer/.vnc/self.pem 6080 localhost:5901 >/dev/null 2>&1 &" || true

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
echo "  - VNC: vnc://localhost:5901"
echo "  - Web VNC: http://localhost:6080"
echo "  - Rails: http://localhost:3000"
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
echo "/home/developer/welcome.sh" >> /home/developer/.bashrc

# Keep container running
log "All services started. Container is ready!"
tail -f /dev/null