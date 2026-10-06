{ lib, ... }:
{
  # Each service has its own homelab.<name>.enable switch (set in ../default.nix)
  # and web UIs are published at <name>.<domain> by ./proxy.nix. Services kept the
  # ports and in-container paths they had under Docker Compose, so their
  # existing databases and settings carried over unchanged.
  imports = [
    ./proxy.nix
    ./jellyfin.nix
    ./audiobookshelf.nix
    ./filebrowser.nix
    ./immich.nix
    ./torrent.nix
    ./samba.nix
    ./calibre-web.nix
    ./komga.nix
    ./updates.nix
  ];

  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "evilwizard.duckdns.org";
      description = "DuckDNS domain; services are served at <name>.<domain>.";
    };
    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "eno1";
      description = "Wired LAN interface, for services opened to devices without Tailscale.";
    };
    media = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/media";
      description = "Media subvolume: torrents/ and library/.";
    };
    photos = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/photos";
      description = "Photos subvolume; Immich's library lives in immich/.";
    };
  };
}
