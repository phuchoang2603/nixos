-- Set transparent
local function set_transparent()
	local groups =
		{ "Normal", "NormalNC", "LineNr", "Folded", "NonText", "SpecialKey", "VertSplit", "SignColumn", "EndOfBuffer" }
	for _, group in ipairs(groups) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
	end
end

-- Read Stylix-generated colors
local palette_path = vim.fn.expand("~/.config/stylix/palette.json")
local file = io.open(palette_path, "r")

if file then
	local content = file:read("*a")
	file:close()

	local ok, palette = pcall(vim.json.decode, content)
	if ok and palette then
		-- Apply base16 colors from Stylix palette
		require("base16-colorscheme").setup({
			base00 = "#" .. palette.base00,
			base01 = "#" .. palette.base01,
			base02 = "#" .. palette.base02,
			base03 = "#" .. palette.base03,
			base04 = "#" .. palette.base04,
			base05 = "#" .. palette.base05,
			base06 = "#" .. palette.base06,
			base07 = "#" .. palette.base07,
			base08 = "#" .. palette.base08,
			base09 = "#" .. palette.base09,
			base0A = "#" .. palette.base0A,
			base0B = "#" .. palette.base0B,
			base0C = "#" .. palette.base0C,
			base0D = "#" .. palette.base0D,
			base0E = "#" .. palette.base0E,
			base0F = "#" .. palette.base0F,
		})
		set_transparent()
	else
		vim.notify("Failed to parse Stylix palette.json", vim.log.levels.WARN)
		vim.cmd.colorscheme("base16-default-dark")
		set_transparent()
	end
else
	vim.notify("Stylix palette.json not found, using default theme", vim.log.levels.WARN)
	vim.cmd.colorscheme("base16-default-dark")
end

-- Icons
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

-- Statusline
local statusline = require("mini.statusline")
statusline.setup({
	use_icons = vim.g.have_nerd_font or true, -- Force true if you know you have one
	content = {
		active = function()
			local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
			local diff = statusline.section_diff({ trunc_width = 75 })
			local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
			local recording = vim.fn.reg_recording()
			local macro = recording ~= "" and ("Recording @" .. recording) or ""
			local filename = statusline.section_filename({ trunc_width = 140 })
			local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })

			return statusline.combine_groups({
				{ hl = mode_hl, strings = { mode } },
				{ hl = "MiniStatuslineDevinfo", strings = { diff, diagnostics } },
				"%<", -- Mark general truncate point
				{ hl = "MiniStatuslineFilename", strings = { filename } },
				"%=", -- End left alignment
				{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
				{ hl = mode_hl, strings = { macro } },
			})
		end,
	},
})
