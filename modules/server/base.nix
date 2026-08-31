{
  pkgs,
  user,
  ...
}:

{
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
}
