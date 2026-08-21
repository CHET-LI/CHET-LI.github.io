#!/usr/bin/env bash
# 全门禁：构建门 → 链接门 → 质量门（串行，任一失败即停）
# 用法：./scripts/all-gates.sh [content-file.md]

set -uo pipefail

cd "$(dirname "$0")/.."

echo "🚦 [全门禁] 开始三重门禁检查..."
echo ""

./scripts/build-gate.sh
echo ""

./scripts/link-gate.sh
echo ""

./scripts/quality-gate.sh "$@"
echo ""

echo "🎉 [全门禁] 三重门禁全部通过！可安全发布。"