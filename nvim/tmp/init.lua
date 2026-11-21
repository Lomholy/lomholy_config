-- -----------------------------------------------------------------------------------------------
-- General configuration
-- -----------------------------------------------------------------------------------------------
-- Basic settings

vim.opt.hlsearch = true
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.spelllang = "en_gb"
vim.opt.title = true
vim.opt.titlestring = "nvim"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "number"
vim.opt.colorcolumn = "80"
-- Leader (this is here so plugins etc pick it up)
vim.g.mapleader = " " -- anywhere you see <leader> = hit ,

-- use nvim-tree instead
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Use system clipboard
vim.opt.clipboard:append({ "unnamed", "unnamedplus" })

-- Display settings
vim.opt.termguicolors = true
-- vim.o.background = "light" -- set to "dark" for dark theme

-- Scrolling and UI settings
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.sidescrolloff = 8
vim.opt.scrolloff = 8

-- Persist undo (persists your undo history between sessions)
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.undofile = true

-- Tab stuff
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Search configuration
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.gdefault = true

-- open new split panes to right and below (as you probably expect)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- LSP
vim.lsp.inlay_hint.enable(false)
-- -----------------------------------------------------------------------------------------------
-- Plugin list
-- -----------------------------------------------------------------------------------------------
local plugins = {
  -- { "github/copilot.vim"},
	{ "nvim-lua/plenary.nvim" }, -- used by several other plugins
	{ "rebelot/kanagawa.nvim" }, -- Kanagawa theme (feel free to choose another!)
--  {"ribru17/bamboo.nvim"}, -- Osaka theme
-- {"ellisonleao/gruvbox.nvim", priority = 1000 , config = true, opts = ...},
	{ "nvim-tree/nvim-web-devicons", lazy = true }, -- used by lualine and nvim-tree
	{ "nvim-lualine/lualine.nvim" }, -- Status line
	{ "nvim-tree/nvim-tree.lua" }, -- File browser

	-- Telescope command menu
	{ "nvim-telescope/telescope.nvim" },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },

	-- TreeSitter
	{ "nvim-treesitter/nvim-treesitter", priority = 1000, build = ":TSUpdate" },

	-- LSP
	{ "mason-org/mason.nvim" }, -- installs LSP servers
	{ "neovim/nvim-lspconfig" }, -- configures LSPs
	{ "mason-org/mason-lspconfig.nvim" }, -- links installed to configured
	{ "stevearc/conform.nvim" }, -- Formatting where the LSP doesn't
  { "lewis6991/gitsigns.nvim" },
  {"MeanderingProgrammer/render-markdown.nvim"},

	-- LaTeX
	{
		"lervag/vimtex", -- compiling with latexmk, PDF viewer sync, motions and text objects
		lazy = false, -- vimtex must not be lazy-loaded
		init = function()
			if vim.fn.has("mac") == 1 then
				vim.g.vimtex_view_method = "skim"
			else
				vim.g.vimtex_view_method = vim.fn.executable("xdotool") == 1 and "zathura" or "zathura_simple"
			end
		end,
	},
	{
		"L3MON4D3/LuaSnip", -- snippet engine
		version = "v2.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip").config.setup({ enable_autosnippets = true })
			require("luasnip.loaders.from_vscode").lazy_load() -- friendly-snippets
		end,
	},
	{
		"iurimateus/luasnip-latex-snippets.nvim", -- math autosnippets (mk, ff, //, ...)
		dependencies = { "L3MON4D3/LuaSnip", "lervag/vimtex" },
		config = function() require("luasnip-latex-snippets").setup() end,
	},

	{
		"saghen/blink.cmp", -- Blink completion tool (LSP, snippets etc)
		dependencies = { "L3MON4D3/LuaSnip" },

		---@module 'blink.cmp'
		---@type blink.cmp.Config

		version = "1.*", -- release tags ship a prebuilt fuzzy matcher, so no Rust toolchain is needed
		opts = {
			keymap = { preset = "enter" },
			snippets = { preset = "luasnip" },
			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
}
-- -----------------------------------------------------------------------------------------------
-- Plugin installation
-- -----------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(plugins)

-- -----------------------------------------------------------------------------------------------
-- Plugin config
-- -----------------------------------------------------------------------------------------------
vim.cmd.colorscheme("kanagawa") -- activate the theme
require("lualine").setup() -- the status line
require("nvim-tree").setup() -- the tree file browser panel
require("telescope").setup() -- command menu

-- -----------------------------------------------------------------------------------------------
-- Treesitter (syntax highlighting and related stuff!)
-- -----------------------------------------------------------------------------------------------
-- NB: Make sure to add more from this list!
-- https://github.com/nvim-treesitter/nvim-treesitter/tree/master#supported-languages
-- Building parsers needs the tree-sitter CLI and a C compiler
-- On macOS, build with Apple's clang even when a conda env has set CC
-- (tree-sitter reads CC_<target> before CC)
if vim.fn.has("mac") == 1 and vim.fn.executable("/usr/bin/clang") == 1 then
	vim.env.CC_aarch64_apple_darwin = "/usr/bin/clang"
	vim.env.CC_x86_64_apple_darwin = "/usr/bin/clang"
end
if vim.fn.executable("tree-sitter") == 1 then
	require("nvim-treesitter").install({ "typescript", "python", "rust", "go" })
end
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "typescript", "python", "rust", "go" },
	callback = function() pcall(vim.treesitter.start) end, -- parser may still be installing on first launch
})
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

-- -----------------------------------------------------------------------------------------------
-- LSP
-- -----------------------------------------------------------------------------------------------
-- NB: These will FAIL if you don't have the language toolchains installed!
-- NB: Make sure to add more from this list!
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = {
		"eslint",
		"ruff",
		"texlab",
	},
	-- Never start spell-checking servers, even if installed through Mason
	automatic_enable = {
		exclude = { "ltex", "ltex_plus", "harper_ls", "typos_lsp", "cspell_ls", "codebook" },
	},
})

require("conform").setup({
	default_format_opts = { lsp_format = "fallback" }, -- Many languages can be formatted directly by their LSP
	formatters_by_ft = { -- but some can't, so conform is for those ones
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		json = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
    python = { "isort", "black" },
	},
})


-- ----------------------------------------------------------------------------
-- LaTeX
-- ----------------------------------------------------------------------------
-- Start latexmk in continuous mode when a project opens. It rebuilds the main
-- document whenever any file it includes is saved. \ll toggles it.
vim.api.nvim_create_autocmd("User", {
	pattern = "VimtexEventInitPost",
	command = "VimtexCompile!",
})


-- ----------------------------------------------------------------------------
-- Mccode stuff
-- ----------------------------------------------------------------------------

vim.filetype.add({
  extension = {
    instr = 'mccode',
    comp = 'mccode',
  },
})


-- Utilities (optional but handy)
local util = require('lspconfig.util')  -- provides root_pattern, dirname

-- Prevent duplicate clients per buffer by checking existing clients
local function has_client_for_buf(bufnr, name)
  for _, client in pairs(vim.lsp.get_active_clients({bufnr = bufnr})) do
    if client.name == name then return true end
  end
  return false
end


local uv = vim.uv or vim.loop
-- McStas language server from Lomholy/VS_for_McStas (server/python), see README
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'mccode',
  callback = function(args)
    if vim.fn.executable('mcstas-language-server') == 0 then return end

    local bufnr = args.buf
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = (fname ~= '' and vim.fs.dirname(fname)) or uv.cwd()

    -- prevent duplicate clients for the same root
    for _, c in ipairs(vim.lsp.get_clients({ name = 'mcstas_language_server' })) do
      if c.config.root_dir == root then
        -- already running for this workspace: just attach this buffer
        vim.lsp.buf_attach_client(bufnr, c.id)
        return
      end
    end
  
    vim.lsp.start({
      name = 'mcstas_language_server',  -- use a stable, lowercase, no-space name
      cmd = { 'mcstas-language-server' },
      root_dir = root,
      on_init = function(client, init_result)
      end,

      on_attach = function(client, b)
        -- Mark for debugging and set buffer-local opts if needed
        vim.b[b].mcstas_lsp_attached = true

        -- Example keymaps:
        local opts = { buffer = b, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K',  vim.lsp.buf.hover,      opts)
      end,

    })
  end,
})
-- -----------------------------------------------------------------------------------------------
-- Keymap settings
-- -----------------------------------------------------------------------------------------------
-- Basic keys
-- vim.keymap.set("n", "q", "<C-r>") -- "u" is undo, I map "q" to redo


-- Search navigation
-- n is always forward, N is always backward
-- ' is now forward and ; is backward
vim.keymap.set("n", "n", "v:searchforward ? 'n' : 'N'", { expr = true })
vim.keymap.set("n", "N", "v:searchforward ? 'N' : 'n'", { expr = true })
vim.keymap.set({ "n", "v" }, ";", "getcharsearch().forward ? ',' : ';'", { expr = true })
vim.keymap.set({ "n", "v" }, "'", "getcharsearch().forward ? ';' : ','", { expr = true })

-- toggle line numbers and wrap
vim.keymap.set("n", "<leader>n", ":set nonumber! relativenumber!<CR>")
vim.keymap.set("n", "<leader>w", ":set wrap! wrap?<CR>")

-- Moving between splits and resizing
vim.keymap.set("n", "<C-j>", "<C-W><C-J>") -- use Ctrl-j (and so on) to move between splits
vim.keymap.set("n", "<C-k>", "<C-W><C-K>")
vim.keymap.set("n", "<C-l>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")

-- nvim-tree (file browser settings)
vim.keymap.set("n", "<C-t>", ":NvimTreeFocus<CR>")
vim.keymap.set("n", "<C-f>", ":NvimTreeFindFile<CR>")
vim.keymap.set("n", "<C-c>", ":NvimTreeClose<CR>")

-- Formatting
vim.keymap.set("n", "<leader>fo", require("conform").format)

local tele_builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", tele_builtin.git_files, {}) -- ,ff to find git files
vim.keymap.set("n", "<leader>pf", tele_builtin.find_files, {}) -- ,fa to find any files
vim.keymap.set("n", "<leader>fg", tele_builtin.live_grep, {}) -- ,fg to ripgrep
vim.keymap.set("n", "<leader>fb", tele_builtin.buffers, {}) -- ,fb to see recent buffers
vim.keymap.set("n", "<leader>fh", tele_builtin.help_tags, {}) -- ,fh to search help





-- Make the colors transparent
vim.cmd [[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
]]

