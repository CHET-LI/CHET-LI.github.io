#!/usr/bin/env bash
# 构建门：hugo --minify 无报错
# 用法：./scripts/build-gate.sh

set -euo pipefail

echo "🔨 [构建门] 开始构建验证..."
cd "$(dirname "$0")/.."

if hugo --minify; then
    echo "✅ [构建门] 通过：hugo --minify 无报错"
    exit 0
else
    echo "❌ [构建门] 失败：hugo --minify 报错"
    exit 1
fi