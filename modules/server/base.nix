{
  pkgs,
  user,
  ...
}:

{
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
