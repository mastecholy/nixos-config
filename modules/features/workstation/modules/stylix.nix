{ pkgs, ... }:
{
  # Color scheme: modules/common/nixos-core/modules/stylix.nix
  stylix = {
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sizes.terminal = 16;
    };

    opacity.terminal = 0.8;
  };
}
