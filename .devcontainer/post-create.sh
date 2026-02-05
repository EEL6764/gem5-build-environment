#!/bin/bash
set -e

echo "=========================================="
echo "Setting up gem5 Development Environment"
echo "=========================================="

# Create command history directory
mkdir -p /commandhistory
touch /commandhistory/.bash_history

# Create symlink to gem5 in workspace if user wants it
# Named gem5_base to avoid conflicts with user's own gem5 folder
if [ ! -L "/workspace/gem5_base" ] && [ ! -d "/workspace/gem5_base" ]; then
    echo "Creating symlink to gem5 source..."
    ln -sf /opt/gem5 /workspace/gem5_base
fi

# If user has their own gem5 fork, provide instructions
echo ""
echo "=========================================="
echo "gem5 Development Environment Ready!"
echo "=========================================="
echo ""
echo "📁 gem5 source code: /opt/gem5"
echo "📁 Your workspace:   /workspace"
echo ""
echo "🔗 A symlink '/workspace/gem5_base' points to the gem5 source."
echo ""
echo "💡 To use your own gem5 fork:"
echo "   1. Clone your fork to /workspace/my-gem5"
echo "   2. cd /workspace/my-gem5"
echo "   3. Build: scons build/X86/gem5.opt -j\$(nproc)"
echo ""
echo "🛠️  Quick commands:"
echo "   Build gem5:    cd /opt/gem5 && scons build/X86/gem5.opt -j\$(nproc)"
echo "   Run example:   /opt/gem5/build/X86/gem5.opt /opt/gem5/configs/example/se.py --cmd=/bin/ls"
echo "   Build help:    build-gem5.sh --help"
echo ""
