require("sidekick").setup({
	cli = {
		mux = {
			enabled = true,
			backend = "tmux",
		},
	},
})
