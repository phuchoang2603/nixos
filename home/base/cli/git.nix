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
      ".direnv/"
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
      customCommands = [
        {
          key = "C";
          command = ''
            git diff --staged | pi --model github-copilot/gpt-5.4-mini -p \
            'Generate a git commit message for these staged changes using Conventional Commits. 
            Include a concise summary line, a blank line, and short bullet points description of the changes. 
            Output ONLY the raw text with no markdown, no code blocks, and no explanations.' \
            > /tmp/commit_msg && git commit -e -F /tmp/commit_msg
          '';
          description = "Generate commit message with Opencode";
          context = "files";
          output = "terminal";
        }
      ];
    };
  };
}
