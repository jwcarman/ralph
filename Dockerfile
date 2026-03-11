# =============================================================================
# Ralph Loop — Docker Sandbox
# =============================================================================
# Runs the ralph loop in an isolated container.
# Claude gets access only to this project directory and nothing else.
# The ANTHROPIC_API_KEY is passed in at runtime — never baked into the image.
# =============================================================================

FROM ubuntu:24.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    ca-certificates \
    gnupg \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (required by Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally (latest)
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user — principle of least privilege
RUN useradd -m -s /bin/bash ralph
USER ralph
WORKDIR /home/ralph/project

# Configure git identity for commits inside the container
RUN git config --global user.email "ralph@loop.local" \
    && git config --global user.name "Ralph Loop"

# The project directory is mounted at runtime via -v
# entrypoint.sh configures git credentials then execs loop.sh
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
