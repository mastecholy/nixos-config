{ pkgs, ... }:
let
  # Any file name (without .yaml) from:
  #   ls $(nix build --no-link --print-out-paths nixpkgs#base16-schemes)/share/themes
  scheme = "catppuccin-macchiato";
in
{
  # System-level stylix; also auto-imports the stylix module into home-manager.
  # Colors are shared by every host (shell, prompt, neovim); fonts, cursor and
  # opacity live in the workstation feature.
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${scheme}.yaml";
    # Match the scheme above ("light" for light schemes); also picks
    # noctalia's dark/light mode
    polarity = "dark";
  };
}
