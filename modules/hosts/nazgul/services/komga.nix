{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab;
  port = 25600;

  # Sorts the old manga/comics folders into library/{manga,comics}; dry run
  # unless --apply (see the script's header)
  organize-comics = pkgs.writers.writePython3Bin "organize-comics" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ../scripts/organize-comics.py);
in
{
  options.homelab.komga.enable = lib.mkEnableOption "Komga (native service)";

  config = lib.mkIf cfg.komga.enable {
    # nixpkgs is behind upstream; use the newer release until it catches up
    # (this override then switches itself off)
    nixpkgs.overlays = [
      (final: prev: {
        komga =
          if lib.versionOlder prev.komga.version "1.28.1" then
            prev.komga.overrideAttrs {
              version = "1.28.1";
              src = final.fetchurl {
                url = "https://github.com/gotson/komga/releases/download/1.28.1/komga-1.28.1.jar";
                hash = "sha256-ANW+aVNpjeCtlmuqt9YttAlxxRyBDrTNnxExXDbMouY=";
              };
            }
          else
            prev.komga;
      })
    ];

    # Manga and comics server with a web UI at komga.<domain> and OPDS at
    # /opds/v1.2/catalog for KOReader. Libraries are added in its web UI:
    # library/manga and library/comics under the media subvolume.
    services.komga = {
      enable = true;
      settings.server.port = port;
    };

    # OPDS for the Kobo (KOReader), which isn't on Tailscale:
    # http://<nazgul's LAN IP>:25600/opds/v1.2/catalog
    networking.firewall.interfaces.${cfg.lanInterface}.allowedTCPPorts = [ port ];

    environment.systemPackages = [ organize-comics ];
  };
}
