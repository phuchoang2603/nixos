{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "felix";
        email = "xuanphuc.a1gv@gmail.com";
      };

      pull.rebase = true;
      init.defaultBranch = "main";

      commit.gpgSign = false;
      format.signOff = true;
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
