#!/usr/bin/env bash
# 链接门：检查 public/ 内部链接、图片、锚点全通
# 用法：./scripts/link-gate.sh
# 前置：需先运行构建门生成 public/

set -uo pipefail

echo "🔗 [链接门] 开始链接检查..."
cd "$(dirname "$0")/.."

PUBLIC_DIR="public"
if [[ ! -d "$PUBLIC_DIR" ]]; then
    echo "❌ [链接门] 失败：public/ 目录不存在，请先运行构建门"
    exit 1
fi

FAILED=0

# 1. 检查内部 HTML 链接（相对路径）
echo "  → 检查内部 HTML 链接..."
while IFS= read -r -d '' file; do
    # 提取 href 属性值，使用数组避免 subshell 问题
    mapfile -t links < <(grep -oE 'href="([^"]*)"' "$file" | sed 's/href="//;s/"//' || true)
    for link in "${links[@]}"; do
        # 跳过外部链接、锚点、mailto、tel、javascript
        case "$link" in
            http*|mailto:*|tel:*|javascript:*|"#"*) continue ;;
        esac
        # 处理带锚点的链接：/path#anchor -> /path
        target="${link%%#*}"
        # 补全为 public/ 下的路径
        if [[ "$target" == /* ]]; then
            if [[ "$target" == */ ]]; then
                target_path="$PUBLIC_DIR${target}index.html"
            else
                target_path="$PUBLIC_DIR${target}/index.html"
            fi
        else
            # 相对链接，基于当前文件所在目录
            dir=$(dirname "$file")
            if [[ "$target" == */ ]]; then
                target_path="$dir/${target}index.html"
            else
                target_path="$dir/${target}/index.html"
            fi
        fi
        # 规范化路径
        target_path=$(realpath -m "$target_path" 2>/dev/null || echo "$target_path")
        if [[ ! -f "$target_path" ]]; then
            echo "    ❌ 断链：$file -> $link (期望: $target_path)"
            FAILED=1
        fi
    done
done < <(find "$PUBLIC_DIR" -name '*.html' -print0)

# 2. 检查图片引用
echo "  → 检查图片引用..."
while IFS= read -r -d '' file; do
    mapfile -t imgs < <(grep -oE 'src="([^"]*)"' "$file" | sed 's/src="//;s/"//' || true)
    for img in "${imgs[@]}"; do
        case "$img" in
            http*|data:*) continue ;;
        esac
        if [[ "$img" == /* ]]; then
            img_path="$PUBLIC_DIR$img"
        else
            dir=$(dirname "$file")
            img_path="$dir/$img"
        fi
        img_path=$(realpath -m "$img_path" 2>/dev/null || echo "$img_path")
        if [[ ! -f "$img_path" ]]; then
            echo "    ❌ 缺失图片：$file -> $img (期望: $img_path)"
            FAILED=1
        fi
    done
done < <(find "$PUBLIC_DIR" -name '*.html' -print0)

# 3. 检查锚点（同页锚点）
echo "  → 检查页面内锚点..."
while IFS= read -r -d '' file; do
    # 提取所有 id 属性
    ids=$(grep -oE 'id="([^"]*)"' "$file" | sed 's/id="//;s/"//' | sort -u)
    # 提取所有 #anchor 引用
    mapfile -t anchors < <(grep -oE 'href="[^"]*#[^"]*"' "$file" | sed 's/.*#\([^"]*\)".*/\1/' || true)
    for anchor in "${anchors[@]}"; do
        if ! echo "$ids" | grep -qx "$anchor"; then
            echo "    ❌ 缺失锚点：$file -> #$anchor"
            FAILED=1
        fi
    done
done < <(find "$PUBLIC_DIR" -name '*.html' -print0)

if [[ $FAILED -eq 0 ]]; then
    echo "✅ [链接门] 通过：所有内部链接、图片、锚点均通"
    exit 0
else
    echo "❌ [链接门] 失败：存在断链/缺失资源 (FAILED=$FAILED)"
    exit 1
fi