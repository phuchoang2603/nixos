{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    auto-cpufreq
  ];

  services.auto-cpufreq.enable = true;
}
