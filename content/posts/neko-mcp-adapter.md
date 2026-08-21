---
title: "NEKO MCP 适配器：从零到可用的工程实录"
date: 2026-08-15
draft: true
tags: ["MCP", "Agent", "工程化", "NEKO"]
categories: ["AI Agent 工程"]
series: ["MCP 适配器系列"]
---

## 背景

QwenPaw 内置了 `neko_tools_mcp`，但生产环境需要把它适配到我们的 Harness 框架里。本文记录完整适配过程：从协议对齐、工具注册、错误处理到压测验收。

## 核心挑战

1. **协议不统一**：MCP 标准 vs NEKO 自定义扩展
2. **工具发现机制**：动态注册 vs 静态声明
3. **超时与重试**：长耗时工具（如 `project_scan`）的优雅处理
4. **上下文污染**：大体积 tool_result 如何不爆上下文窗口

## 适配架构

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Harness    │────▶│  NEKO MCP Adapter│────▶│  neko_tools_mcp │
│  (Agent)    │     │  (协议转换+治理)  │     │  (MCP Server)   │
└─────────────┘     └──────────────────┘     └─────────────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
              ┌─────────┐   ┌──────────┐
              │ 缓存层  │   │ 熔断/限流 │
              └─────────┘   └──────────┘
```

## 关键代码片段

### 工具注册表映射

```python
# adapter/tool_registry.py
NEKO_TOOL_MAP = {
    "task_memory_update": "neko_tools_mcp__task_memory_update",
    "task_memory_get": "neko_tools_mcp__task_memory_get",
    "directive_store": "neko_tools_mcp__directive_store",
    "directive_render": "neko_tools_mcp__directive_render",
    "proactive_band": "neko_tools_mcp__proactive_band",
    # ... 其余 14 个工具
}
```

### 熔断装饰器

```python
# adapter/resilience.py
from functools import wraps
import asyncio

def circuit_breaker(failure_threshold=5, recovery_timeout=30):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 熔断逻辑
            pass
        return wrapper
    return decorator
```

## 压测结果

| 指标 | 适配前 | 适配后 | 目标 |
|------|--------|--------|------|
| P99 延迟 | 2.3s | 420ms | <500ms |
| 错误率 | 12% | 0.3% | <1% |
| 上下文膨胀 | 严重 | 可控 | - |

## 经验总结

1. **先跑通最小链路**，再加治理层
2. **工具元数据标准化** 是自动化发现的前提
3. **大结果外置存储**（context_manager_mcp）是必须的
4. **可观测性要内置**，不是事后补

---

> 下一篇：`context_manager_mcp` 如何把 500KB tool_result 压成 2KB 引用