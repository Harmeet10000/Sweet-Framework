#!/bin/bash
# Sweet Framework - Dependency Installation Script
# Run this to install all C library dependencies

set -e

echo "🔧 Installing Sweet Framework Dependencies..."

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "📦 Detected Linux - using apt"
    
    # Update package list
    sudo apt update
    
    # Install core dependencies
    echo "Installing libuv..."
    sudo apt install -y libuv1-dev
    
    echo "Installing liburing..."
    sudo apt install -y liburing-dev
    
    echo "Installing build tools..."
    sudo apt install -y build-essential cmake git clang
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📦 Detected macOS - using brew"
    
    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Installing libuv..."
    brew install libuv
    
    echo "⚠️  Note: liburing is Linux-only, skipping on macOS"
    
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

# Clone and build llhttp
echo "📥 Cloning llhttp..."
if [ ! -d "vendor/llhttp" ]; then
    mkdir -p vendor
    cd vendor
    git clone https://github.com/nodejs/llhttp.git
    cd llhttp
    git checkout v9.2.1
    npm install
    make
    cd ../..
else
    echo "✓ llhttp already cloned"
fi

# Clone yyjson
echo "📥 Cloning yyjson..."
if [ ! -d "vendor/yyjson" ]; then
    mkdir -p vendor
    cd vendor
    git clone https://github.com/ibireme/yyjson.git
    cd yyjson
    git checkout 0.8.0
    mkdir -p build
    cd build
    cmake ..
    make
    cd ../../..
else
    echo "✓ yyjson already cloned"
fi

# Clone c-ares (async DNS)
echo "📥 Cloning c-ares..."
if [ ! -d "vendor/c-ares" ]; then
    mkdir -p vendor
    cd vendor
    git clone https://github.com/c-ares/c-ares.git
    cd c-ares
    git checkout v1.28.1
    mkdir -p build
    cd build
    cmake ..
    make
    cd ../../..
else
    echo "✓ c-ares already cloned"
fi

echo "✅ All dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "1. Verify Mojo is installed: mojo --version"
echo "2. Run tests: mojo test"
echo "3. Start building: see docs/todo.md"
