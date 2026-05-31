#!/bin/bash
# Sweet Framework - Quick Start Script
# Run this to test your setup

set -e

echo "🚀 Sweet Framework - Quick Start"
echo "================================"
echo ""

# Step 1: Check Mojo
echo "1️⃣  Checking Mojo installation..."
if command -v mojo &> /dev/null; then
    echo "   ✅ Mojo found: $(mojo --version 2>&1 | head -1)"
else
    echo "   ❌ Mojo not found! Install from: https://www.modular.com/mojo"
    exit 1
fi
echo ""

# Step 2: Check dependencies
echo "2️⃣  Checking C library dependencies..."
if [ -f "vendor/llhttp/build/libllhttp.so" ]; then
    echo "   ✅ llhttp built"
else
    echo "   ❌ llhttp not found. Run: ./scripts/install-deps.sh"
    exit 1
fi

if [ -f "vendor/yyjson/build/libyyjson.a" ]; then
    echo "   ✅ yyjson built"
else
    echo "   ❌ yyjson not found. Run: ./scripts/install-deps.sh"
    exit 1
fi

if [ -f "vendor/c-ares/build/lib/libcares.so" ]; then
    echo "   ✅ c-ares built"
else
    echo "   ❌ c-ares not found. Run: ./scripts/install-deps.sh"
    exit 1
fi
echo ""

# Step 3: Set library path
echo "3️⃣  Setting library path..."
export LD_LIBRARY_PATH=$PWD/vendor/llhttp/build:$PWD/vendor/c-ares/build/lib:$LD_LIBRARY_PATH
echo "   ✅ LD_LIBRARY_PATH set"
echo ""

# Step 4: Run tests
echo "4️⃣  Running FFI tests..."
echo ""

echo "   Testing libuv FFI..."
if mojo run tests/test_ffi_libuv.mojo 2>&1; then
    echo "   ✅ libuv test passed"
else
    echo "   ⚠️  libuv test failed (this is expected, needs fixing)"
fi
echo ""

echo "   Testing llhttp FFI..."
if mojo run tests/test_ffi_llhttp.mojo 2>&1; then
    echo "   ✅ llhttp test passed"
else
    echo "   ⚠️  llhttp test failed (this is expected, needs fixing)"
fi
echo ""

echo "   Testing yyjson FFI..."
if mojo run tests/test_ffi_yyjson.mojo 2>&1; then
    echo "   ✅ yyjson test passed"
else
    echo "   ⚠️  yyjson test failed (this is expected, needs fixing)"
fi
echo ""

# Summary
echo "================================"
echo "📊 Summary"
echo "================================"
echo ""
echo "✅ Mojo installed"
echo "✅ Dependencies built"
echo "✅ Library path set"
echo "⚠️  FFI tests need work (expected)"
echo ""
echo "📖 Next Steps:"
echo "   1. Read: NEXT-STEPS.md"
echo "   2. Read: docs/WEEK-2-STARTED.md"
echo "   3. Fix FFI issues"
echo "   4. Implement connection handling"
echo ""
echo "🚀 You're ready to start Week 2!"
echo ""
