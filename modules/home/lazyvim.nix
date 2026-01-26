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
        nushell.enable = true;
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

    # LazyVim configuration files (ported from dotfiles)
    configFiles = ./lazyvim-config;
    
    # Additional packages if needed
    extraPackages = with pkgs; [];
  };

  xdg.configFile."nvim/stylua.toml".text = ''
    indent_type = "Spaces"
    indent_width = 2
    column_width = 120
  '';
}
