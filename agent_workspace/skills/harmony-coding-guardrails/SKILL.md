---
name: harmony-coding-guardrails
description: Guardrails for writing HarmonyOS ArkTS code with higher correctness. Use before skeleton planning, page implementation, or integration fixes when routing, entry pages, page registration, navigation scaffolds, imports, or runtime white-screen risks may be involved.
---

# Harmony Coding Guardrails

Use this skill before writing or restructuring HarmonyOS ArkTS code when correctness matters more than feature depth.

This skill is preventive. It should be used during coding stages, not only after a failure.

## Workflow

1. Read this file first.
2. For concrete pitfalls and fixes, read `references/common-guardrails.md`.
3. If the task involves multi-page structure, page registration, `EntryAbility`, `main_pages.json`, startup pages, or `@Entry`, consult the reference before writing code.
4. Apply the guardrails while planning or coding, not only after a compile or runtime failure.

## When To Use

- Skeleton stage planning shared routes, entry pages, or navigation scaffolds
- Page workers editing page files, shared navigation, or page-level routing behavior
- Integration workers fixing compile-pass/runtime-fail issues such as white screens

## Key Rule

If a project has multiple pages, the skeleton stage owns:

- initial page registration
- `EntryAbility.loadContent(...)` alignment
- `main_pages.json` alignment
- shared navigation scaffold ownership

Do not leave these decisions fragmented across page workers.
