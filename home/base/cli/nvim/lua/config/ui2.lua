require("vim._core.ui2").enable({
	enable = true,
	msg = {
		---@type 'cmd'|'msg'
		---@type string|table<string, 'cmd'|'msg'|'pager'>
		targets = "cmd",
		cmd = {
			height = 0.5,
		},
		dialog = {
			height = 0.5,
		},
		msg = {
			height = 0.5,
			timeout = 4000,
		},
		pager = {
			height = 1,
		},
	},
})
