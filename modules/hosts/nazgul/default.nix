{ lib, ... }:
{
  imports = [
    ./storage.nix
    ./wol.nix
    ./services
  ];

  # Homelab services, see ./services/*.nix
  homelab = {
    reverseProxy.enable = true;
    jellyfin.enable = true;
    audiobookshelf.enable = true;
    filebrowser.enable = true;
    immich.enable = true;
    torrent.enable = true;
    samba = {
      enable = true;
      saveUsers = [ "alex" ];
    };
    calibreWeb.enable = true;
    komga.enable = true;
  };

  # Home server: NVMe system disk + 2x 8 TB btrfs RAID1 data array
  # (./storage.nix). Report generated on install by nixos-anywhere.
  hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./hardware_report.json) ./hardware_report.json;
}
