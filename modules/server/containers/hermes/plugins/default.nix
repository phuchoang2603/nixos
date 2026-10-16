{ pkgs }:

{
  application-accounts = ./application-accounts;
  realtime-voice = ./realtime-voice;

  # Catalog provider pinned to its supported revision. Keep scheduled-job
  # transcripts out of long-term memory until upstream handles these platforms.
  hindsight =
    pkgs.runCommand "hermes-hindsight-plugin"
      {
        src = pkgs.fetchFromGitHub {
          owner = "vectorize-io";
          repo = "hindsight";
          rev = "d56c4acdf59c41957613d399094cdf8c489b060c";
          sparseCheckout = [ "hindsight-integrations/hermes" ];
          hash = "sha256-8QxHgplP1FjlwRzynj+sr9mmQjATkJBLiW9BtDawNPY=";
        };
      }
      ''
        cp -r $src/hindsight-integrations/hermes $out
        chmod -R u+w $out
        substituteInPlace $out/__init__.py --replace-fail \
          'if not self._auto_retain' \
          'if not self._auto_retain or self._platform in ("cron", "subagent")'
      '';
}
