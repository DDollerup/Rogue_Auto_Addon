# Agent instructions

## Runtime compatibility

- Target Turtle WoW's Lua 5.0 runtime.
- Do not use Lua 5.1+ syntax such as `...` varargs or the length operator `#`.
- Use explicit function arguments, `table.getn`, and the Lua 5.0 `arg` conventions only when verified against the client runtime.
- Prefer APIs available in the 1.12.1 addon environment; do not assume newer WoW or Lua APIs exist.
- Keep TOC file order explicit and ensure every loaded module is Lua 5.0-compatible.
