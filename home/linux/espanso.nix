{ pkgs, config, ... }:

{
  services.espanso = {
    enable = true;
    package = pkgs.espanso;
    waylandSupport = true;
    x11Support = false;

    # Main configuration
    configs = {
      default = {
        toggle_key = "ALT";
        auto_restart = true;
        search_shortcut = "ALT+SPACE";
      };
    };

    # Match configurations
    matches = {
      # Base matches (available everywhere)
      "base" = {
        matches = [
          # Current date
          {
            trigger = ":date";
            replace = "{{mydate}}";
            vars = [
              {
                name = "mydate";
                type = "date";
                params = {
                  format = "%Y-%m-%d";
                };
              }
            ];
          }
          # Shell command output
          {
            trigger = ":shell";
            replace = "{{output}}";
            vars = [
              {
                name = "output";
                type = "shell";
                params = {
                  cmd = "echo 'Hello from your shell'";
                };
              }
            ];
          }
        ];
      };

      # Personal information
      "personal" = {
        matches = [
          {
            trigger = ":name";
            replace = "Felix Hoang";
          }
          {
            trigger = ":fname";
            replace = "Felix";
          }
          {
            trigger = ":lname";
            replace = "Hoang";
          }
          {
            trigger = ":uname";
            replace = "phuchoang2603";
          }
          {
            trigger = ":uid";
            replace = "83765874";
          }
          {
            trigger = ":phone";
            replace = "8136097656";
          }
          {
            trigger = ":addr";
            replace = "12810 University Club Dr, #203 Tampa, Florida, 33612 United States";
          }
          {
            trigger = ":street";
            replace = "12810 University Club Dr";
          }
          {
            trigger = ":school";
            replace = "University of South Florida";
          }
          {
            trigger = ":gmail";
            replace = "xuanphuc.a1gv@gmail.com";
          }
          {
            trigger = ":omail";
            replace = "phuchoang@usf.edu";
          }
        ];
      };

      # Social media links
      "link" = {
        matches = [
          {
            trigger = "l.yt";
            replace = "https://www.youtube.com/@phuchoangxuan1089";
          }
          {
            trigger = "l.gh";
            replace = "https://github.com/phuchoang2603";
          }
          {
            trigger = "l.lk";
            replace = "https://www.linkedin.com/in/phuchoang2603/";
          }
          {
            trigger = "l.fb";
            replace = "https://www.facebook.com/phuchoang2603/";
          }
        ];
      };

      # Obsidian-specific expansions
      "obsidian" = {
        matches = [
          {
            trigger = "o.yt";
            replace = ''{{< youtubeLite id="{{clipb}}" label="Video demo" >}}'';
            vars = [
              {
                name = "clipb";
                type = "clipboard";
              }
            ];
          }
          {
            trigger = "o.gh";
            replace = ''{{< github repo="{{clipb}}" showThumbnail=true >}}'';
            vars = [
              {
                name = "clipb";
                type = "clipboard";
              }
            ];
          }
        ];
      };

      # Kaomoji (emoji) expansions
      "kaomoji" = {
        matches = [
          {
            trigger = "k.joy";
            replace = "{{output}}";
            vars = [
              {
                name = "output";
                type = "random";
                params = {
                  choices = [
                    "(* ^ ω ^)"
                    "(´ ∀ ` *)"
                    "☆*:.｡.o(≧▽≦)o.｡.:*☆"
                    "(o^▽^o)"
                    "(⌒▽⌒)☆"
                    "<(￣︶￣)>"
                    "。.:☆*:･'(*⌒―⌒*)))"
                    "ヽ(・∀・)ﾉ"
                    "(´｡• ω •｡`)"
                    "(￣ω￣)"
                    "｀;:゛;｀;･(°ε° )"
                    "(o･ω･o)"
                    "(＠＾◡＾)"
                    "ヽ(*・ω・)ﾉ"
                    "(o_ _)ﾉ彡☆"
                    "(^人^)"
                    "(o´▽`o)"
                  ];
                };
              }
            ];
          }
        ];
      };
    };
  };
}
