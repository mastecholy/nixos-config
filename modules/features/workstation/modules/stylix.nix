{ pkgs, ... }:
{
  # Colors: modules/common/nixos-core/modules/stylix.nix (static scheme) and
  # modules/features/home-manager/modules/desktop/theme.nix (wallpaper)
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

    # Qt apps are themed from the wallpaper palette through qt5ct/qt6ct
    # (modules/features/home-manager/modules/desktop/theme.nix), not
    # Stylix's Kvantum theme
    targets.qt.enable = false;
  };

  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
}
