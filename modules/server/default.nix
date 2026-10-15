{
  imports = [
    ../common
    ./base.nix
    ./deployment.nix
    ./nvidia.nix
    ./docker.nix
    ./storage.nix
    ./secrets.nix
    ./containers
    ./ssh.nix
  ];
}
