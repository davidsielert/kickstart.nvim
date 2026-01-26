# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **kickstart-modular.nvim**, a modular fork of kickstart.nvim. It's an educational Neovim configuration starter, not a distribution. The configuration is split across multiple files for easier understanding and customization.

## Architecture

**Entry Point Flow:**
1. `init.lua` - Sets leader key (`<space>`), Nerd Font flag, then requires modules in order
2. `lua/options.lua` - Vim editor settings
3. `lua/keymaps.lua` - Global keybindings and autocommands
4. `lua/lazy-bootstrap.lua` - Auto-installs lazy.nvim plugin manager on first run
5. `lua/lazy-plugins.lua` - Central plugin specifications, loads all plugin configs

**Plugin Configuration:**
- Each plugin has its own file in `lua/kickstart/plugins/`
- Plugin specs follow lazy.nvim format: `{ 'owner/repo', opts = {}, config = function() ... end }`
- Optional plugins (debug, indent_line) are commented out in `lazy-plugins.lua`

**Customization Points:**
- `lua/custom/plugins/` - Add custom plugins here (uncomment import line in `lazy-plugins.lua` first)
- LSP servers configured in `lua/kickstart/plugins/lspconfig.lua` in the `servers` table

## Commands

**Plugin Management:**
- `:Lazy` - Open lazy.nvim UI to view/manage plugins
- `:Lazy update` - Update all plugins
- `:Mason` - Manage LSP servers, formatters, linters

**Health Checks:**
- `:checkhealth` - Verify Neovim version and external dependencies (git, make, unzip, ripgrep)

**Code Formatting:**
```bash
stylua .                    # Format all Lua files
stylua --check .            # Check formatting without changes
```

## Code Style

Lua files use StyLua with settings in `.stylua.toml`:
- 160 column width
- 2-space indentation
- Single quotes preferred
- No parentheses on function calls when possible

## External Dependencies

Required: git, make, unzip, gcc, ripgrep, Neovim 0.9.4+
Optional: Nerd Font (set `vim.g.have_nerd_font = true` in init.lua)
