# Project Coding & Aesthetic Standards

## 1. Zero-Emoji Policy in Code & Technical Artifacts
- **Strictly prohibit decorative / mobile emojis** in all code files, comments, docstrings, variable names, log outputs, and UI strings across all programming languages (JavaScript, TypeScript, Python, Bash, Go, Rust, Lua, C/C++, HTML/CSS, etc.).
- Do NOT use mobile/WhatsApp-style emojis (e.g., 🚀, 🔥, 💡, 🎙️, 🎉, 🎬, ✨) in:
  - Source code comments (e.g., avoid `// 🚀 starting server`)
  - Log statements and print statements (e.g., avoid `console.log("🔥 connected")` or `echo "✨ listo"`)
  - Error messages and exceptions
  - Terminal outputs, CLI menus, prompts, and OSD messages
- **Exceptions**: Only use emojis if explicitly and strictly required by the user as functional data, or when requested as specific UI assets. For web interfaces, always prefer clean SVG/vector icons (Lucide, Feather, FontAwesome) or text over colored chat emojis.

## 2. Minimalist & Elegant Terminal Aesthetic (Omarchy Style)
- Follow the clean, disciplined aesthetic of modern minimalist open-source CLI tools (such as Omarchy, Charm/Gum, Fzf, Arch/CachyOS system utilities):
  - **Console Prefixes**: Use clean, subtle terminal prefixes such as `:: `, `-> `, `* `, `• `, `[+]`, `[-]`, `[!]`.
  - **Status Glyphs**: Use clean unicode glyphs when needed: `✓`, `✕`, `▸`, `─`, `│`, `└`.
  - **Color Palette**: Use subtle, restrained ANSI colors (dim cyan, muted green, bold white, subtle gray) rather than loud, garish combinations.
  - **Formatting**: Clean, monospace-aligned tables, headers, and bullet points without emoji clutter.

## 3. Conversational Scope
- This aesthetic restriction applies to codebases, scripts, terminal outputs, commits, and documentation. In direct conversational chat with the user, natural and friendly communication is permitted.
