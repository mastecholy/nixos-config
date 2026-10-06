{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.extra.battlenet;
in
{
  options.gaming.extra.battlenet.enable =
    lib.mkEnableOption "Battle.net through Lutris (Warcraft, WoW)"
    // {
      default = config.gaming.extra.enable;
    };

  # Battle.net itself is installed inside a Wine prefix with Lutris's
  # Battle.net installer (lutris.net/games/battlenet), which sets up its own
  # Wine runner and DXVK; games are then installed from the launcher
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
      # System Wine for winetricks and one-off fixes inside the prefix.
      # wineWow64 (Wine's new WoW64 mode, runs 32-bit apps too) is in the
      # binary cache; the older wineWowPackages builds aren't and compile
      # from source for a long time on every Wine update
      wineWow64Packages.stagingFull
      winetricks
      # Downloads and updates Wine-GE / Proton-GE runners for Lutris
      protonplus
    ];
  };
}
