local function run_vuln_audit()
	local report_file = "reports.sarif"

	vim.notify("Running Govulncheck...", vim.log.levels.INFO, { title = "Security Audit" })

	vim.fn.jobstart("govulncheck -format sarif ./... > " .. report_file, {
		on_exit = function(_, exit_code)
			if exit_code == 0 or exit_code == 3 then -- 3 often means vulns found
				vim.notify("Audit complete", vim.log.levels.INFO)
			else
				vim.notify("Govulncheck failed", vim.log.levels.ERROR)
			end
		end,
	})
end

vim.keymap.set("n", "<leader>cv", run_vuln_audit, { desc = "Go: Run & View Vulnerabilities" })
