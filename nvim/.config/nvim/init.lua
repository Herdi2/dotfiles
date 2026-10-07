-- Division of options inspired by kickstart.nvim

vim.g.mapleader = " "

do
	-- CHAPTER 1: CORE OPTIONS

	-- Indentation Configuration
	-- NOTE: Overwritten by ftplugin when possible
	vim.o.tabstop = 2
	vim.o.expandtab = true
	vim.o.shiftwidth = 2
	vim.o.autoindent = true

	-- Relative line numbers
	vim.o.number = true
	vim.o.relativenumber = true

	-- Use rounded pop-up borders
	vim.o.winborder = "rounded"

	-- Sync clipboard between OS and Neovim.
	vim.schedule(function()
		vim.o.clipboard = "unnamedplus"
	end)

	-- Enable break indent
	vim.o.breakindent = true

	-- Save undo history
	vim.o.undofile = true

	-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
	vim.o.ignorecase = true
	vim.o.smartcase = true

	-- Keep signcolumn on by default
	vim.o.signcolumn = "yes"

	-- Preview substitutions live, as you type!
	vim.o.inccommand = "split"

	-- Show which line your cursor is on
	vim.o.cursorline = true

	-- Hide mode (already in statusline)
	vim.o.showmode = false

	-- Minimal number of screen lines to keep above and below the cursor.
	vim.o.scrolloff = 5

	-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
	-- instead raise a dialog asking if you wish to save the current file(s)
	-- See `:help 'confirm'`
	vim.o.confirm = true

	-- Disable inline error messages
	vim.diagnostic.config({ virtual_text = false })

	-- Highlight when yanking (copying) text
	vim.api.nvim_create_autocmd("TextYankPost", {
		desc = "Highlight when yanking (copying) text",
		group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
		callback = function()
			vim.hl.on_yank()
		end,
	})
end

do
	-- CHAPTER 2: Built-in keybinds

	-- Split configuration
	vim.keymap.set("n", "<leader>hs", "<cmd>:split <CR>", { desc = "[H]orizontally [S]plit window" })
	vim.keymap.set("n", "<leader>vs", "<cmd>:vsplit <CR>", { desc = "[V]ertically [S]plit window" })

	-- Display error message in pop-up window
	vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open [e]rror window" })

	-- Diagnostic keymaps
	vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

	-- Clear highlights on search when pressing <Esc> in normal mode
	--  See `:help hlsearch`
	vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
end

do
	-- CHAPTER 3: PLUGINS
	-- Use the built-in vim.pack
	local gh = function(x)
		return "https://github.com/" .. x
	end

	-- Load plugins
	vim.pack.add({
		gh("neovim/nvim-lspconfig"),
		gh("echasnovski/mini.nvim"),
		gh("ibhagwan/fzf-lua"),
		gh("nvim-treesitter/nvim-treesitter"),
		gh("mason-org/mason.nvim"),
		gh("mason-org/mason-lspconfig.nvim"),
		gh("lewis6991/gitsigns.nvim"),
		gh("hrsh7th/nvim-cmp"),
		gh("hrsh7th/cmp-nvim-lsp"),
		gh("hrsh7th/cmp-buffer"),
		gh("hrsh7th/cmp-path"),
		gh("stevearc/conform.nvim"),
    gh("nyoom-engineering/oxocarbon.nvim"),
	})

  --# Aesthetics
  vim.o.background = "dark"
  vim.cmd.colorscheme("oxocarbon")

	--# mini.nvim setup
	-- Better around/inside textrobjects (e.g. `ci'` - Change Inside Quote)
	require("mini.ai").setup({ n_lines = 500 })
	-- Add/delete/replace surroundings (brackets, quotes, etc.)
	require("mini.surround").setup()
	-- Simple statusline setup
	local statusline = require("mini.statusline")
	statusline.setup({ use_icons = vim.g.have_nerd_font })
	statusline.section_location = function()
		return "%2l:%-2v"
	end

	--# fzf setup
	local fzf = require("fzf-lua")
	fzf.setup({
		winopts = { preview = { layout = "vertical" } },
	})

	-- Seach over files
	vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
	vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
	-- LSP search with fzf, once an LSP is attached
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local function map(mode, lhs, fn, desc)
				vim.keymap.set(mode, lhs, fn, { buffer = ev.buf, desc = desc })
			end
			map("n", "grd", fzf.lsp_definitions, "Definitions")
			map("n", "grr", fzf.lsp_references, "References")
			map("n", "gri", fzf.lsp_implementations, "Implementations")
			map("n", "grt", fzf.lsp_typedefs, "Type definitions")
			map("n", "grs", fzf.lsp_document_symbols, "Document symbols")
			map("n", "<leader>fs", fzf.lsp_live_workspace_symbols, "Workspace symbols")
			map({ "n", "x" }, "gra", fzf.lsp_code_actions, "Code actions")
		end,
	})

	--# Tree-sitter setup
	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			-- Auto-update parsers with tree-sitter
			local name, kind = ev.data.spec.name, ev.data.kind
			if name == "nvim-treesitter" and kind == "update" then
				if not ev.data.active then
					vim.cmd.packadd("nvim-treesitter")
				end
				vim.cmd("TSUpdate")
			end
		end,
	})

	require("nvim-treesitter").install({
		"bash",
		"c",
		"diff",
		"html",
		"lua",
		"luadoc",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
		"haskell",
	})

	--# LSP
	-- Mason is used to download LSPs
	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = {
			"lua_ls",
			"basedpyright",
		},
	})
	-- Load HLS from GHCup before Mason, since Mason doesn't compile against system GHC (and therefore doesn't work)
	vim.env.PATH = vim.env.HOME .. "/.ghcup/bin:" .. vim.env.PATH

	--# Gitsigns
	require("gitsigns").setup({
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
	})

	--# Completion
	local cmp = require("cmp")

	cmp.setup({
		snippet = {
			expand = function(args)
				vim.snippet.expand(args.body)
			end,
		},

		completion = { completeopt = "menu,menuone,noinsert" },

		-- Rounded borders
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},

		mapping = cmp.mapping.preset.insert({
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-Space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({ select = true }),

			-- Jump through snippet placeholders
			["<Tab>"] = cmp.mapping(function(fallback)
				if vim.snippet.active({ direction = 1 }) then
					vim.snippet.jump(1)
				else
					fallback()
				end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if vim.snippet.active({ direction = -1 }) then
					vim.snippet.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
		}),

		sources = cmp.config.sources({
			{ name = "nvim_lsp" },
			{ name = "path" },
		}, {
			{ name = "buffer" },
		}),
	})

	-- Tell every LSP server that the client supports cmp's completion features
	vim.lsp.config("*", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(),
	})

	--# Code formatter
	require("conform").setup({
		formatters_by_ft = {
			python = { "black" },
		},
	})

	vim.keymap.set({ "n", "v" }, "<leader>fm", function()
		require("conform").format({ async = true, lsp_format = "fallback" })
	end, { desc = "Format buffer" })
end
