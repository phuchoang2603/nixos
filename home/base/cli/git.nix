{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      commit.gpgSign = false;
      format.signOff = true;
    };
    settings = {
      user = {
        name = "felix";
        email = "xuanphuc.a1gv@gmail.com";
      };

      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
      };

      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        commit = {
          # This forces Lazygit to add the -s flag to every commit command
          signOff = true;
        };
      };
    };
  };
}
