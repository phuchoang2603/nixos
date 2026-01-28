{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (texlive.combine {
      inherit (texlive)
        scheme-medium
        latexmk
        collection-latexextra
        collection-binextra
        collection-fontsextra
        ;
    })
  ];
}
