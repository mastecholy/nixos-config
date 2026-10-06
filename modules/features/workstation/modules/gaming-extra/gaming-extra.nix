{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.extra;
in
{
  # Niche gaming setup, enabled per host (modules/hosts/<name>/default.nix).
  # Each area lives in its own file here (battlenet.nix, later fightcade,
  # emulators...) with its own switch that defaults to gaming.extra.enable
  options.gaming.extra.enable = lib.mkEnableOption "extra gaming tools (Battle.net, emulators, ...)";

  config = lib.mkIf cfg.enable {
    # GE-Proton as a selectable compatibility tool in Steam (Properties →
    # Compatibility), handy for non-Steam games added to the library
    programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ];

    # gamemoderun %command% / mangohud %command% / gamescope -- %command%
    programs.gamemode.enable = true;
    programs.gamescope.enable = true;
    environment.systemPackages = [ pkgs.mangohud ];
  };
}
