local status, sfer = pcall(require, "sfer")
if not status then
	return
end

sfer.setup({
	sidebar = {
		width = 40,
		border = "rounded",
	},
	indent = {
		rule = 0,
		location = 2,
		alert = 4,
	},
})

vim.cmd("SarifSidebar")
