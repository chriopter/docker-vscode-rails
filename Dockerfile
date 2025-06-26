# Use Ubuntu Desktop image as base
FROM kasmweb/core-ubuntu-focal:1.13.0

USER root

# Environment setup
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/developer

# Install development tools
RUN apt-get update && apt-get install -y \
    # Development essentials
    curl \
    wget \
    git \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libffi-dev \
    libyaml-dev \
    # SSH server
    openssh-server \
    # Editors
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby
RUN apt-get update && apt-get install -y ruby-full ruby-dev && \
    gem install bundler rails foreman ruby-lsp && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create developer user
RUN useradd -m -s /bin/bash -u 1000 developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'developer:developer' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Switch to developer user
USER developer
WORKDIR /home/developer

# Install VS Code extensions
RUN code --install-extension Shopify.ruby-lsp && \
    code --install-extension misogi.ruby-rubocop && \
    code --install-extension castwide.solargraph && \
    code --install-extension sorbet.sorbet-vscode-extension

# Configure bundler
RUN mkdir -p ~/.bundle && \
    bundle config set --local path '~/.bundle' && \
    bundle config set --local bin '~/.bundle/bin' && \
    echo 'export PATH="$HOME/.bundle/bin:$PATH"' >> ~/.bashrc && \
    echo 'export GEM_HOME="$HOME/.bundle"' >> ~/.bashrc

# Create workspace
RUN mkdir -p ~/workspace

# Switch back to root for startup
USER root

# Copy setup script
COPY scripts/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Expose ports
EXPOSE 22 3000 6901

# Start services
CMD ["/usr/local/bin/setup.sh"]