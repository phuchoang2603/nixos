require("nvim-treesitter-textobjects").setup({
	select = {
		enable = true,
		lookahead = true,
		selection_modes = {
			["@parameter.outer"] = "v", -- char wise
			["@function.outer"] = "V", -- line wise
			["@class.outer"] = "<c-v>", -- block wise
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
	{ { "n", "x", "o" }, "[f", mv.goto_previous_start, "@function.outer" },

	-- Class
	{ { "n", "x", "o" }, "]c", mv.goto_next_start, "@class.outer" },
	{ { "n", "x", "o" }, "[c", mv.goto_previous_start, "@class.outer" },

	-- Blocks (Conditionals & Loops)
	{ { "n", "x", "o" }, "]b", mv.goto_next, "@block.outer", "Next Block" },
	{ { "n", "x", "o" }, "[b", mv.goto_previous, "@block.outer", "Prev Block" },

	-- Parameters / Arguments
	{ { "n", "x", "o" }, "]a", mv.goto_next_start, "@parameter.inner", "Next Argument" },
	{ { "n", "x", "o" }, "[a", mv.goto_previous_start, "@parameter.inner", "Prev Argument" },

	-- Assignments / Key-Value Pairs
	{ { "n", "x", "o" }, "]k", mv.goto_next_start, "@assignment.outer", "Next Assignment" },
	{ { "n", "x", "o" }, "[k", mv.goto_previous_start, "@assignment.outer", "Prev Assignment" },
}) do
	local modes, lhs, fn, query = map[1], map[2], map[3], map[4]

	local qstr = (type(query) == "table") and table.concat(query, ", ") or query

	vim.keymap.set(modes, lhs, function()
		fn(query, "textobjects")
	end, { desc = "Move: " .. qstr })
end

-- Autostart treesitter
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		local filetype = vim.bo.filetype
		if filetype and filetype ~= "" then
			pcall(vim.treesitter.start)
		end
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo.foldmethod = "expr"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
