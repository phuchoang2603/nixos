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
          signOff = true;
        };
      };
      customCommands = [
        {
          key = "C";
          command = ''
            git diff --staged | /etc/profiles/per-user/felix/bin/opencode run 'Generate a concise git commit message for these staged changes. Output ONLY the raw commit message with no markdown, no code blocks, no backticks, no explanations. Use conventional commit format.' --attach http://localhost:4096 --model github-copilot/gpt-5.4-mini > /tmp/commit_msg && git commit -e -F /tmp/commit_msg
          '';
          description = "Generate commit message with Opencode";
          context = "files";
          output = "terminal";
        }
      ];
    };
  };
}
