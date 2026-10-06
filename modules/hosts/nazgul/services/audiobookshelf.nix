{ config, lib, ... }:
let
  cfg = config.homelab;
  state = "/var/lib/audiobookshelf";
in
{
  options.homelab.audiobookshelf.enable = lib.mkEnableOption "Audiobookshelf (native service)";

  config = lib.mkIf cfg.audiobookshelf.enable {
    # Config and metadata in /var/lib/audiobookshelf/{config,metadata}
    services.audiobookshelf = {
      enable = true;
      host = "127.0.0.1";
      port = 13378;
    };

    # Use the same paths as the old Docker container: Audiobookshelf stores
    # them in its database (covers and metadata under /metadata, the library
    # folder as /audiobooks)
    systemd.services.audiobookshelf = {
      environment = {
        CONFIG_PATH = "/config";
        METADATA_PATH = "/metadata";
      };
      serviceConfig.BindPaths = [
        "${state}/config:/config"
        "${state}/metadata:/metadata"
        "${cfg.media}/library/lit/audiobooks:/audiobooks"
      ];
    };
    systemd.tmpfiles.rules = [
      "d ${state}/config 0750 audiobookshelf audiobookshelf -"
      "d ${state}/metadata 0750 audiobookshelf audiobookshelf -"
    ];
  };
}
