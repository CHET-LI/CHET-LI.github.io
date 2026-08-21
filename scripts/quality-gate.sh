#!/usr/bin/env bash
# 质量门：内容自查清单 + 可自动化的基础校验
# 用法：./scripts/quality-gate.sh [content-file.md]
# 前置：需先通过构建门、链接门

set -uo pipefail

echo "📋 [质量门] 开始质量自查..."
cd "$(dirname "$0")/.."

CONTENT_FILE="${1:-}"
FAILED=0
WARNINGS=0

# 可自动化的基础校验
check_frontmatter() {
    local file="$1"
    echo "  → 检查 Front Matter 完整性：$file"
    local missing=()
    grep -q '^title:' "$file" || missing+=("title")
    grep -q '^date:' "$file" || missing+=("date")
    grep -q '^tags:' "$file" || missing+=("tags")
    grep -q '^categories:' "$file" || missing+=("categories")
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "    ⚠️  缺失字段：${missing[*]}"
        ((WARNINGS++))
    fi
}

check_draft_status() {
    local file="$1"
    if grep -q '^draft: true' "$file"; then
        echo "    ℹ️  草稿状态：$file (draft: true)"
    fi
}

check_length() {
    local file="$1"
    local words=$(grep -v '^---$' "$file" | sed '1,/^---$/d' | wc -w)
    echo "    📏 正文字数：约 $words 词"
    if [[ $words -lt 300 ]]; then
        echo "    ⚠️  内容较短（<300 词），建议扩充"
        ((WARNINGS++))
    elif [[ $words -gt 5000 ]]; then
        echo "    ⚠️  内容较长（>5000 词），建议拆分"
        ((WARNINGS++))
    fi
}

check_code_blocks() {
    local file="$1"
    local lang_count=$(grep -c '^```[a-zA-Z]' "$file" || true)
    if [[ $lang_count -gt 0 ]]; then
        echo "    💻 代码块：$lang_count 个（已标注语言）"
    fi
    # 检查无语言标注的代码块
    local no_lang=$(grep -c '^```$' "$file" || true)
    if [[ $no_lang -gt 0 ]]; then
        echo "    ⚠️  发现 $no_lang 个无语言标注的代码块"
        ((WARNINGS++))
    fi
}

check_dead_refs() {
    local file="$1"
    # 检查是否引用了不存在的文件/图片（相对路径）
    local refs
    mapfile -t refs < <(grep -oE '\]\(([^)]+)\)' "$file" | sed 's/.*(//;s/)//' || true)
    for ref in "${refs[@]}"; do
        # 跳过外部链接、锚点
        [[ "$ref" == http* ]] && continue
        [[ "$ref" == mailto:* ]] && continue
        [[ "$ref" == \#* ]] && continue
        # 相对/绝对路径，检查静态资源目录
        if [[ "$ref" == /* ]] || [[ "$ref" == ../* ]] || [[ "$ref" == ./* ]]; then
            if [[ ! -f "static$ref" && ! -f "content/$ref" && ! -f "$ref" ]]; then
                echo "    ⚠️  疑似失效引用：$ref"
                ((WARNINGS++))
            fi
        fi
    done
}

# === 主流程 ===
if [[ -n "$CONTENT_FILE" ]]; then
    # 单文件模式
    if [[ ! -f "$CONTENT_FILE" ]]; then
        echo "❌ [质量门] 失败：文件不存在 $CONTENT_FILE"
        exit 1
    fi
    check_frontmatter "$CONTENT_FILE"
    check_draft_status "$CONTENT_FILE"
    check_length "$CONTENT_FILE"
    check_code_blocks "$CONTENT_FILE"
    check_dead_refs "$CONTENT_FILE"
else
    # 全站模式：检查所有 content/posts/*.md
    echo "  → 全站模式：检查 content/posts/ 下所有文章"
    for file in content/posts/*.md; do
        [[ -f "$file" ]] || continue
        check_frontmatter "$file"
        check_draft_status "$file"
        check_length "$file"
        check_code_blocks "$file"
        check_dead_refs "$file"
    done
fi

# === 人工核验清单（输出到 stdout，供人工确认）===
cat <<'EOF'

📝 === 质量门·人工核验清单（必须逐项确认） ===

□ 数据真实：文中数据、引用、链接均可追溯到一手来源，无编造
□ 无幻觉：技术细节、代码片段、命令均经实测可跑通，非 LLM 幻觉
□ 可追溯：关键结论有出处/实验/日志支撑，读者可复现验证
□ 长度克制：单文聚焦单一主题，避免流水账；超长拆系列
□ 术语统一：全文术语、缩写、命名风格一致
□ 格式规范：标题层级、代码块语言、列表风格符合站点规范
□ SEO 基础：title/description/tags 完整，含核心关键词
□ 无敏感信息：无密钥、内网地址、私人隐私

EOF

if [[ $FAILED -gt 0 ]]; then
    echo "❌ [质量门] 失败：$FAILED 项硬性校验未通过"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️  [质量门] 通过（含 $WARNINGS 项警告），请人工复核上述清单"
    exit 0
else
    echo "✅ [质量门] 通过：自动化校验无阻断项，请人工确认上述清单"
    exit 0
fi