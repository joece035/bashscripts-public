---
description: "Use when working with the JOE Block Engine in functions/joe-block/. Covers styling, data providers, and the Rows → Layout → Theme → Renderer pipeline."
applyTo: "functions/joe-block/**"
---

# JOE Block Engine Instructions

The JOE Block Engine is a modular terminal UI framework for rendering status dashboards.

## Architecture & Data Flow
1.  **Public API:** `entry.sh` (functions: `m`, `m_random`, `m_animate`, `dashboard_array`).
2.  **Data Providers:** Functions in `block/status.sh` (e.g., `status_new`, `op_profile`) that collect system data and pass it to `dashboard_array`.
3.  **Layout:** `block/layout.sh` calculates dimensions (`_LAYOUT[]`) based on data rows.
4.  **Theme:** `block/theme.sh` loads style definitions from `styles/block_style.sh` into `_THEME[]` and compiles color specs.
5.  **Renderer:** `block/renderer.sh` draws the final borders, rows, and separators using the compiled theme.

## File Placement Rules
| Task | Location |
|------|----------|
| Add a new status dashboard | Add a new function in `block/status.sh` (or a new file in `block/` and source it in `entry.sh`). |
| Add a new visual style | Add a `_style_<name>()` function in `styles/block_style.sh`. |
| Modify row/border rendering | `block/renderer.sh`. |
| Modify width/centering logic | `block/layout.sh`. |

## Key Conventions
- **SSOT Compliance:** Never hardcode colors. Use the helpers from `01-colors.sh` (e.g., `c`, `cn`, `color`) within style definitions or data providers.
- **Style Definition:** Use `set_ <var> <value>` in `styles/block_style.sh` to populate the global `_THEME` and `_LAYOUT` associative arrays.
- **Cross-Shell Support:** `entry.sh` is designed to work in both **bash** and **zsh**. Avoid using bash-specific features (like `[[ ... ]]` or `${var//pattern/replace}`) in the public API if possible, or use the provided fallbacks.
- **Idempotent Sourcing:** Modules in `block/` are sourced automatically by `entry.sh`. Do not source them manually in other scripts.

## Forbidden Patterns
- **Direct Rendering:** Do not call `renderer.sh` functions directly from data providers. Always pass data to `dashboard_array`.
- **Hardcoded Paths:** Use `$SCRIPTS_PATH` or `$SSOT` for referencing files outside the block engine.
- **Global Side Effects:** Data providers should only set the `ROWS` array (or equivalent) and call `dashboard_array`. Avoid polluting the global namespace with temporary variables.
