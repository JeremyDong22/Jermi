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

# Clear com.apple.provenance xattr and re-adhoc-sign.
# Required when the repo lives in an iCloud-synced path (~/Desktop, ~/Documents)
# on Apple Silicon — otherwise AMFI kills the binary on launch.
if [[ "$(uname)" == "Darwin" ]]; then
	xattr -c "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null || true
	codesign --force --sign - "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null || true
fi

echo ""
echo "Installation complete!"
echo ""
echo "Make sure ${INSTALL_DIR} is in your PATH:"
echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
echo ""
echo "Then run: jermi"
