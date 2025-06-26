# Multi-stage build to get Ruby from official image
FROM ruby:3.3-slim AS ruby-source

# Multi-stage build to get Node from official image  
FROM node:20-slim AS node-source

# Main image based on Ubuntu
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Copy Ruby from official image
COPY --from=ruby-source /usr/local /usr/local

# Copy Node from official image
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
    ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Basic utilities
    curl \
    wget \
    git \
    # Build tools for gems with native extensions
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libffi-dev \
    libyaml-dev \
    # SSH server
    openssh-server \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    # Desktop environment
    xfce4 \
    xfce4-terminal \
    # noVNC for web-based VNC access
    novnc \
    websockify \
    # X11 utilities
    x11-xserver-utils \
    # Other utilities
    sudo \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Rails and other Ruby gems
RUN gem install bundler rails foreman ruby-lsp

# Install Yarn
RUN npm install -g yarn

# Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create developer user
RUN useradd -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'developer:developer' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Setup VNC
USER developer
RUN mkdir -p /home/developer/.vnc && \
    echo "developer" | vncpasswd -f > /home/developer/.vnc/passwd && \
    chmod 600 /home/developer/.vnc/passwd

# Configure bundler for user installation
RUN mkdir -p /home/developer/.bundle && \
    cd /home/developer && \
    bundle config set --local path '/home/developer/.bundle' && \
    bundle config set --local bin '/home/developer/.bundle/bin' && \
    echo 'export PATH="/home/developer/.bundle/bin:$PATH"' >> /home/developer/.bashrc && \
    echo 'export GEM_HOME="/home/developer/.bundle"' >> /home/developer/.bashrc && \
    echo 'export BUNDLE_PATH="/home/developer/.bundle"' >> /home/developer/.bashrc

# Install VS Code extensions
RUN code --install-extension Shopify.ruby-lsp && \
    code --install-extension misogi.ruby-rubocop && \
    code --install-extension castwide.solargraph && \
    code --install-extension sorbet.sorbet-vscode-extension

# Create workspace directory
RUN mkdir -p /home/developer/workspace && \
    chown -R developer:developer /home/developer/workspace

# Switch back to root for startup script
USER root

# Copy setup script
COPY scripts/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Expose ports
EXPOSE 22 3000 5901 6080

# Set working directory
WORKDIR /home/developer/workspace

# Start services
CMD ["/usr/local/bin/setup.sh"]