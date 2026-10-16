{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    ignores = [
      ".DS_Store"
      "Thumbs.db"
      "*.swp"
      ".envrc"
      ".devenv/"
      "node_modules/"
      ".vscode/"
    ];

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

    includes = [
      {
        condition = "gitdir:~/repos/work/magnitude-minds/";
        contents = {
          user = {
            name = "felixhoang-mag";
            email = "felixhoang@magnitudeminds.com";
          };
        };
      }
    ];
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        commit = {
          signOff = true;
        };
      };
    };
  };
}
