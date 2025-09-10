#!/bin/bash
# GÉRARD Setup Script for Xiaomi Pad 6 (Non-rooted)
# Production-ready installation with proot-distro

set -e  # Exit on error

echo "🚀 GÉRARD Setup - Xiaomi Pad 6 Installation"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running on Android/Termux
if [[ ! -d "/data/data/com.termux" ]]; then
    error "This script is designed for Termux on Xiaomi Pad 6"
fi

log "Step 1: Update Termux packages"
pkg update -y && pkg upgrade -y

log "Step 2: Install essential packages"
pkg install -y \
    python \
    python-pip \
    git \
    wget \
    curl \
    openssh \
    proot-distro \
    sqlite \
    nodejs \
    nano

log "Step 3: Setup proot-distro Ubuntu environment"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
fi

log "Step 4: Configure Python environment"
python -m pip install --upgrade pip
python -m pip install virtualenv

# Create virtual environment
if [[ ! -d "venv" ]]; then
    log "Creating Python virtual environment"
    python -m virtualenv venv
fi

# Activate virtual environment
source venv/bin/activate

log "Step 5: Install GÉRARD dependencies"
if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
else
    warn "requirements.txt not found, installing minimal dependencies"
    pip install fastapi uvicorn pydantic sqlalchemy celery redis openai
fi

log "Step 6: Create GÉRARD directory structure"
mkdir -p {\
    src/{core,agents,utils,api},\
    config,\
    tests/{unit,integration},\
    docs,\
    scripts,\
    data/{logs,artifacts,cache},\
    .github/workflows\
}

log "Step 7: Set permissions"
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x *.py 2>/dev/null || true

log "Step 8: Initialize SQLite database"
mkdir -p data/db
sqlite3 data/db/gerard.db "CREATE TABLE IF NOT EXISTS agents (id INTEGER PRIMARY KEY, name TEXT, status TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

log "Step 9: Create environment configuration"
if [[ ! -f ".env" ]]; then
    cat > .env << EOF
# GÉRARD Environment Configuration
DEBUG=True
LOG_LEVEL=INFO
DATABASE_URL=sqlite:///data/db/gerard.db
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your_openai_key_here
GITHUB_TOKEN=your_github_token_here
RAILWAY_TOKEN=your_railway_token_here
EOF
fi

log "Step 10: Verify installation"
if python -c "import fastapi, sqlalchemy, celery; print('✅ Core dependencies OK')"; then
    log "✅ GÉRARD installation completed successfully!"
else
    error "❌ Installation verification failed"
fi

echo ""
echo "🎉 GÉRARD is ready!"
echo "Next steps:"
echo "1. Edit .env with your API keys"
echo "2. Run: python quick_gerard.py"
echo "3. Deploy: ./deploy.sh"
echo ""
echo "Repository: https://github.com/TipTopTap/super-doodle"
echo "Documentation: README.md"
echo "==============================================="
