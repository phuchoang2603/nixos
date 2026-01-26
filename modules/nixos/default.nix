{ pkgs, lib, ... }:

{
  imports = [
    ./base
    ./desktop
    ./apps
    ./services
  ];
}
