{ config, hostName, ... }:
let
  # On nazgul's data share (~/nazgul, auto-mounted), one folder per machine
  # so each keeps its own backup chain. Restore another machine's saves
  # with: ludusavi restore --path <its folder>
  backupDir = "${config.home.homeDirectory}/nazgul/backups/ludusavi-backup/${config.home.username}/${hostName}";
in
{
  # Daily game-save backup with Ludusavi. A game is only backed up when its
  # saves changed. The config is managed here, so settings changed in the
  # GUI aren't saved: add custom games or ignores to `settings` instead
  services.ludusavi = {
    enable = true;
    settings = {
      manifest.url = "https://raw.githubusercontent.com/mtkennerly/ludusavi-manifest/master/data/manifest.yaml";
      roots = [
        {
          store = "steam";
          path = "~/.local/share/Steam";
        }
        # Faugus Launcher's Wine prefixes, one per game or launcher
        {
          store = "otherWine";
          path = "~/Faugus/*";
        }
      ];
      backup = {
        path = backupDir;
        # A full backup, then up to 7 differential ones on top of it; two
        # full chains are kept
        retention = {
          full = 2;
          differential = 7;
        };
      };
      restore.path = backupDir;
    };
  };

  # Catch up after the laptop was asleep or off at the scheduled time
  systemd.user.timers.ludusavi.Timer.Persistent = true;
}
