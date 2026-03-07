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
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (required by Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user — principle of least privilege
RUN useradd -m -s /bin/bash ralph
USER ralph
WORKDIR /home/ralph/project

# Configure git identity for commits inside the container
RUN git config --global user.email "ralph@loop.local" \
    && git config --global user.name "Ralph Loop"

# The project directory is mounted at runtime via -v
# The entrypoint just runs the loop
ENTRYPOINT ["/bin/bash", "loop.sh"]
