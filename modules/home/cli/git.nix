{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
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
}
