#!/bin/bash
# Jermi Installation Script
# v1.0 - Install jermi to ~/.local/bin

set -e

INSTALL_DIR="${HOME}/.local/bin"
BINARY_NAME="jermi"

echo "Building Jermi..."
cargo build --release

echo "Installing to ${INSTALL_DIR}/${BINARY_NAME}..."
mkdir -p "${INSTALL_DIR}"
cp target/release/yazi "${INSTALL_DIR}/${BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

echo ""
echo "Installation complete!"
echo ""
echo "Make sure ${INSTALL_DIR} is in your PATH:"
echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
echo ""
echo "Then run: jermi"
