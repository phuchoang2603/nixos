require("quicker").setup({
	keys = {
		{
			">",
			function()
				require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
			end,
			desc = "Expand quickfix context",
		},
		{
			"<",
			function()
				require("quicker").collapse()
			end,
			desc = "Collapse quickfix context",
		},
	},
})

-- Smart Navigation Mappings ([q and ]q)
vim.keymap.set("n", "[q", function()
	if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
		local ok, _ = pcall(vim.cmd.cprev)
		if not ok then
			vim.notify("Beginning of Quickfix list", vim.log.levels.INFO)
		end
	else
		local ok, _ = pcall(vim.cmd.cprev)
		if not ok then
			vim.notify("No Quickfix items", vim.log.levels.WARN)
		end
	end
end, { desc = "Previous Quickfix Item" })

vim.keymap.set("n", "]q", function()
	if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
		local ok, _ = pcall(vim.cmd.cnext)
		if not ok then
			vim.notify("End of Quickfix list", vim.log.levels.INFO)
		end
	else
		local ok, _ = pcall(vim.cmd.cnext)
		if not ok then
			vim.notify("No Quickfix items", vim.log.levels.WARN)
		end
	end
end, { desc = "Next Quickfix Item" })
