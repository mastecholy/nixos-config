{ config, lib, ... }:
let
  cfg = config.homelab;
  inherit (config.sops) placeholder;
  state = "/var/lib/torrent";
  media = cfg.media;
in
{
  options.homelab.torrent.enable = lib.mkEnableOption "qBittorrent behind ProtonVPN via gluetun (containers)";

  config = lib.mkIf cfg.torrent.enable {
    sops.secrets.protonvpn_wireguard_key = { };
    sops.templates."gluetun.env".content = ''
      WIREGUARD_PRIVATE_KEY=${placeholder.protonvpn_wireguard_key}
    '';

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers = {
      # VPN tunnel; qBittorrent shares its network namespace, so it has no
      # route to the internet except through ProtonVPN
      gluetun = {
        image = "qmcgaw/gluetun:v3";
        pull = "always";
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        # qBittorrent web UI, reachable through nginx (qbit.<domain>)
        ports = [ "127.0.0.1:8085:8085" ];
        volumes = [ "${state}/gluetun:/gluetun" ];
        environmentFiles = [ config.sops.templates."gluetun.env".path ];
        environment = {
          TZ = config.time.timeZone;
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          # Only pick ProtonVPN servers that support port forwarding, and push
          # the forwarded port into qBittorrent whenever it changes (requires
          # qBittorrent's "Bypass authentication for clients on localhost")
          VPN_PORT_FORWARDING = "on";
          PORT_FORWARD_ONLY = "on";
          VPN_PORT_FORWARDING_UP_COMMAND = "/bin/sh -c 'wget -O- --retry-connrefused --post-data \"json={\\\"listen_port\\\":{{PORTS}}}\" http://127.0.0.1:8085/api/v2/app/setPreferences 2>&1'";
          # Let qBittorrent reach the LAN (outside the tunnel)
          FIREWALL_OUTBOUND_SUBNETS = "192.168.1.0/24";
        };
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        pull = "always";
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = config.time.timeZone;
          WEBUI_PORT = "8085";
        };
        volumes = [
          "${state}/qbittorrent:/config"
          # Whole media subvolume as one mount, so finished downloads can be
          # hardlinked into the library: save to /data/torrents
          "${media}:/data"
          # Paths existing torrents were added with under Docker
          "${media}/torrents:/downloads"
          "${media}/library/Movies:/movies"
          "${media}/library/Shows:/shows"
          "${media}/library/lit/audiobooks:/audiobooks"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${state} 0750 root root -"
      "d ${state}/gluetun 0700 root root -"
      "d ${state}/qbittorrent 0750 1000 100 -"
    ];
  };
}
