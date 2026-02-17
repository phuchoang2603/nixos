local lint = require("lint")

lint.linters_by_ft = {
	ansible = { "ansible_lint" },
	dockerfile = { "hadolint" },
	go = { "golangcilint" },
	nix = { "statix" },
	python = { "ruff", "mypy" },
	terraform = { "tflint" },
	yaml = { "yamllint" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		lint.try_lint()
	end,
})

vim.keymap.set("n", "<leader>cl", function()
	lint.try_lint()
end, { desc = "Trigger linting" })
