require("nvim-treesitter-textobjects").setup({
	select = {
		enable = true,
		lookahead = true,
		selection_modes = {
			["@parameter.outer"] = "v", -- charwise
			["@function.outer"] = "V", -- linewise
			["@class.outer"] = "<c-v>", -- blockwise
		},
		include_surrounding_whitespace = false,
	},
	move = {
		enable = true,
		set_jumps = true,
	},
})

-- SELECT keymaps
local sel = require("nvim-treesitter-textobjects.select")
for _, map in ipairs({
	{ { "x", "o" }, "af", "@function.outer" },
	{ { "x", "o" }, "if", "@function.inner" },
	{ { "x", "o" }, "ac", "@class.outer" },
	{ { "x", "o" }, "ic", "@class.inner" },
	{ { "x", "o" }, "aa", "@parameter.outer" },
	{ { "x", "o" }, "ia", "@parameter.inner" },
	{ { "x", "o" }, "ad", "@comment.outer" },
	{ { "x", "o" }, "as", "@statement.outer" },
}) do
	vim.keymap.set(map[1], map[2], function()
		sel.select_textobject(map[3], "textobjects")
	end, { desc = "Select " .. map[3] })
end

-- MOVE keymaps
local mv = require("nvim-treesitter-textobjects.move")

for _, map in ipairs({
	-- Function
	{ { "n", "x", "o" }, "]f", mv.goto_next_start, "@function.outer" },
	{ { "n", "x", "o" }, "]F", mv.goto_next_end, "@function.outer" },
	{ { "n", "x", "o" }, "[f", mv.goto_previous_start, "@function.outer" },
	{ { "n", "x", "o" }, "[F", mv.goto_previous_end, "@function.outer" },

	-- Class
	{ { "n", "x", "o" }, "]c", mv.goto_next_start, "@class.outer" },
	{ { "n", "x", "o" }, "]C", mv.goto_next_end, "@class.outer" },
	{ { "n", "x", "o" }, "[c", mv.goto_previous_start, "@class.outer" },
	{ { "n", "x", "o" }, "[C", mv.goto_previous_end, "@class.outer" },

	-- Parameter/Argument
	{ { "n", "x", "o" }, "]a", mv.goto_next_start, "@parameter.inner" },
	{ { "n", "x", "o" }, "]A", mv.goto_next_end, "@parameter.inner" },
	{ { "n", "x", "o" }, "[a", mv.goto_previous_start, "@parameter.inner" },
	{ { "n", "x", "o" }, "[A", mv.goto_previous_end, "@parameter.inner" },

	-- Loops
	{ { "n", "x", "o" }, "]l", mv.goto_next_start, { "@loop.inner", "@loop.outer" } },
	{ { "n", "x", "o" }, "[l", mv.goto_previous_start, { "@loop.inner", "@loop.outer" } },
}) do
	local modes, lhs, fn, query = map[1], map[2], map[3], map[4]

	local qstr = (type(query) == "table") and table.concat(query, ", ") or query

	vim.keymap.set(modes, lhs, function()
		fn(query, "textobjects")
	end, { desc = "Move: " .. qstr })
end

-- Enable folding
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()"

-- Autostart treesitter
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		local filetype = vim.bo.filetype
		if filetype and filetype ~= "" then
			pcall(vim.treesitter.start)
		end
	end,
})
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
