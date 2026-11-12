{ pkgs, ... }:
let
  # Any file name (without .yaml) from:
  #   ls $(nix build --no-link --print-out-paths nixpkgs#base16-schemes)/share/themes
  scheme = "catppuccin-macchiato";
in
{
  # System-level stylix; also auto-imports the stylix module into home-manager.
  # Colors are shared by every host (TTY, prompt, neovim); fonts, cursor and
  # opacity live in the workstation feature. On the workstations the desktop
  # follows the wallpaper instead and this scheme only supplies the accent
  # colors: modules/features/home-manager/modules/desktop/theme.nix
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${scheme}.yaml";
    # Match the scheme above ("light" for light schemes); also picks
    # noctalia's dark/light mode
    polarity = "dark";

    # Stylix's fish theme re-sends the whole palette to the terminal on
    # every shell start, overriding the terminal's own colors (the
    # wallpaper ones on the workstations, also when SSHing into another
    # host). fish's default colors follow the terminal instead
    targets.fish.enable = false;
  };
}
