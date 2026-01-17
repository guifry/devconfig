#!/bin/bash

echo "Python Environment Setup"
echo "========================"

if command -v uv &> /dev/null; then
  echo "uv already installed: $(uv --version)"
else
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "uv installed"
fi
