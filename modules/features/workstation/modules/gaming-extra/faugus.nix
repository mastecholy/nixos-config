{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.extra.faugus;
in
{
  options.gaming.extra.faugus.enable =
    lib.mkEnableOption "Faugus Launcher (Windows games and launchers through UMU/Proton)"
    // {
      default = config.gaming.extra.enable;
    };

  # Runs Windows games and launchers (Battle.net, EA, Epic, ...) with Proton
  # through umu-launcher, one prefix per game. Being tried as a simpler
  # replacement for Lutris (battlenet.nix)
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.faugus-launcher ];
  };
}
