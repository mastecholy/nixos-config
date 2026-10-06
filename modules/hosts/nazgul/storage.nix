{ pkgs, ... }:
{
  # Data array: btrfs RAID1 across both 8 TB disks, labelled "data" at mkfs.
  # Subvolumes (created by hand, see the migration runbook):
  #   media/      torrents/ + library/ (same subvolume so the *arr apps and
  #               qBittorrent can hardlink instead of copying)
  #   photos/     Immich library (irreplaceable, snapshotted)
  #   documents/  documents, keys, saves, share (snapshotted)
  #   games/      game files, minecraft extras (snapshotted weekly)
  #   backups/    backups of other machines
  #   .snapshots/ btrbk snapshots
  fileSystems."/srv/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      # Don't block boot if the array is missing or still being set up
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  environment.systemPackages = [ pkgs.btrfs-progs ];

  # Monthly check of every block against its checksum; repairs from the
  # other disk once both are in RAID1
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/srv/data" ];
    interval = "monthly";
  };

  # Read-only snapshots of the subvolumes worth protecting against deletion
  # or a bad container update; browse them under /srv/data/.snapshots
  services.btrbk.instances.data = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "48h 14d 8w 6m";
      volume."/srv/data" = {
        snapshot_dir = ".snapshots";
        subvolume = {
          photos = { };
          documents = { };
          games.snapshot_preserve = "4w";
        };
      };
    };
  };
  # Skip quietly until the filesystem exists
  systemd.services.btrbk-data.unitConfig.ConditionPathIsMountPoint = "/srv/data";
}
