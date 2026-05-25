# PhantomArch Neovim Configuration

A configuração do Neovim está em `~/.config/nvim/init.lua` e é instalada pelo script de pós-instalação.

## Plugins inclusos
- **catppuccin**: Tema de cores (customizado para Phantom)
- **nvim-treesitter**: Syntax highlighting avançado
- **nvim-lspconfig**: Language Server Protocol
- **nvim-cmp**: Autocompletion
- **telescope.nvim**: Fuzzy finder
- **gitsigns.nvim**: Git integration
- **lualine.nvim**: Status line
- **nvim-autopairs**: Auto close brackets
- **Comment.nvim**: Toggle comments

## Keybindings
- `<Space>` — Leader key
- `<Leader>q` — Diagnostics list
- `<C-h/j/k/l>` — Navigate splits
- `<Esc>` — Clear search highlight

## Adicionar mais plugins
Edite `~/.config/nvim/init.lua` e adicione na seção `require("lazy").setup({...})`.
