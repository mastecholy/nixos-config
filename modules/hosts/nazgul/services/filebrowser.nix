{
  config,
  lib,
  users,
  ...
}:
let
  cfg = config.homelab;
  root = "/srv/data";
in
{
  options.homelab.filebrowser.enable = lib.mkEnableOption "File Browser (native service)";

  config = lib.mkIf cfg.filebrowser.enable {
    # Web file manager for the whole data array; database in
    # /var/lib/filebrowser/database.db. Runs as the primary user so files it
    # creates are owned by you.
    services.filebrowser = {
      enable = true;
      user = users.primary.userName;
      group = "users";
      settings = {
        address = "127.0.0.1";
        port = 8888;
        root = root;
      };
    };

    # The module would chown the served root to the service user with mode
    # 0700 on every boot, locking Jellyfin and Audiobookshelf out of the
    # array; leave the array's root alone
    systemd.tmpfiles.settings.filebrowser.${root} = lib.mkForce { };
    # Files uploaded through File Browser stay readable by the media services
    # (the module default is private, 0077)
    systemd.services.filebrowser.serviceConfig.UMask = lib.mkForce "0022";
  };
}
