{ pkgs, lib, config, ... }:

{
  programs.lazyvim = {
    enable = true;
    
    # Disable treesitter healthcheck since lazyvim-nix provides pre-built parsers
    settings = {
      "health.checks" = false;
    };
    
    # Enable extras based on your current nvim config
    extras = {
      lang = {
        ansible.enable = true;
        clangd.enable = true;
        cmake.enable = true;
        docker.enable = true;
        git.enable = true;
        go.enable = true;
        helm.enable = true;
        json.enable = true;
        markdown.enable = true;
        nix.enable = true;
        python.enable = true;
        terraform.enable = true;
        tex.enable = true;
        toml.enable = true;
        yaml.enable = true;
      };
      
      util = {
        dot.enable = true;
        mini-hipatterns.enable = true;
      };
      
      formatting = {
        prettier.enable = true;
      };
      
      coding = {
        mini-surround.enable = true;
      };
    };
    
    # Custom configuration
    config = {
      options = ''
        vim.opt.wrap = true
        vim.opt.scrolloff = 16
        vim.opt.swapfile = false
        vim.opt.clipboard = "unnamedplus"
      '';
      
      keymaps = ''
        -- Move cursor in Insert Mode using Alt
        vim.keymap.set("i", "<A-h>", "<Left>", { desc = "Move Cursor Left" })
        vim.keymap.set("i", "<A-j>", "<Down>", { desc = "Move Cursor Down" })
        vim.keymap.set("i", "<A-k>", "<Up>", { desc = "Move Cursor Up" })
        vim.keymap.set("i", "<A-l>", "<Right>", { desc = "Move Cursor Right" })
        
        -- Turn off default leader l for lazy
        vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
      '';
    };
    
    # Additional packages if needed
    extraPackages = with pkgs; [];
  };
}
