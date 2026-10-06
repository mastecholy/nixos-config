{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab;
in
{
  options.homelab.jellyfin.enable = lib.mkEnableOption "Jellyfin (native service)";

  config = lib.mkIf cfg.jellyfin.enable {
    # Listens on :8096; data in /var/lib/jellyfin, cache in /var/cache/jellyfin
    services.jellyfin.enable = true;

    # `media-report`: lists movies and shows in formats this GPU or common
    # players handle badly (AV1, Dolby Vision 5, image-only subtitles, ...)
    environment.systemPackages = [
      (pkgs.writers.writePython3Bin "media-report" {
        flakeIgnore = [ "E501" ];
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          "${pkgs.jellyfin-ffmpeg}/bin"
        ];
      } (builtins.readFile ../scripts/media-report.py))
    ];

    # Direct access for LAN devices that can't run Tailscale (the TV):
    # http://<nazgul's LAN IP>:8096, plus client auto-discovery. Everything
    # else reaches Jellyfin through the proxy (jelly.<domain>)
    networking.firewall.interfaces.${cfg.lanInterface} = {
      allowedTCPPorts = [ 8096 ];
      allowedUDPPorts = [ 7359 ];
    };

    # Hardware transcoding on the i5-8500's UHD 630 (VA-API)
    hardware.graphics = {
      enable = true;
      extraPackages = [ pkgs.intel-media-driver ];
    };
    users.users.jellyfin.extraGroups = [
      "render"
      "video"
    ];

    systemd.services.jellyfin = {
      environment.LIBVA_DRIVER_NAME = "iHD";
      # Paths from the old Docker container. Jellyfin stores some of them in
      # its settings and database (cache path, image and metadata paths,
      # library folders), so map them to the native locations instead of
      # rewriting them
      serviceConfig = {
        BindPaths = [
          "/var/lib/jellyfin:/config"
          "/var/cache/jellyfin:/cache"
        ];
        BindReadOnlyPaths = [
          "${cfg.media}/library/Movies:/movies"
          "${cfg.media}/library/Shows:/shows"
        ];
      };
    };
  };
}
