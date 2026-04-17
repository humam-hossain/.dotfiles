--- TODO: Project scoping - project.nvim ---
return {
	"ahmedkhalf/project.nvim",
	init = function()
		require("project_nvim").setup()
	end,
}
