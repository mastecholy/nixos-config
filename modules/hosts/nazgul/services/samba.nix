{
  config,
  lib,
  pkgs,
  users,
  ...
}:
let
  cfg = config.homelab.samba;
  user = users.primary.userName;
  smbpasswd = "${config.services.samba.package}/bin/smbpasswd";
  # Ludusavi game-save backups, one folder per person (see the saves share)
  savesDir = "/srv/data/backups/ludusavi-backup";
in
{
  options.homelab.samba = {
    enable = lib.mkEnableOption "the data array as an SMB share (smb://nazgul/data)";
    saveUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alex" ];
      description = ''
        Other people who back up game saves to nazgul. Each gets a login
        that only reaches smb://nazgul/saves (their own folder in
        ${savesDir}); the password comes from the samba_password_<name>
        secret.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      # Clients find nazgul by name through Tailscale/DNS, so the NetBIOS and
      # domain daemons aren't needed
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = config.networking.hostName;
          "server min protocol" = "SMB3";
          "map to guest" = "never";
          "load printers" = "no";
          "disable spoolss" = "yes";
        };
        data = {
          path = "/srv/data";
          "valid users" = user;
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        # Everyone sees only their own folder (%U = login name); the primary
        # user can read them all through the data share
        saves = {
          path = "${savesDir}/%U";
          "valid users" = lib.concatStringsSep " " ([ user ] ++ cfg.saveUsers);
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    # Accounts for the saves share only: no home, no shell, no SSH
    users.users = lib.genAttrs cfg.saveUsers (_: {
      isSystemUser = true;
      group = "users";
    });

    # SMB only on the LAN and Tailscale
    networking.firewall.interfaces = lib.genAttrs [ config.homelab.lanInterface "tailscale0" ] (_: {
      allowedTCPPorts = [ 445 ];
    });

    # Samba keeps its own password database; keep each user's entry in sync
    # with their samba_password(_<name>) secret, and make sure their saves
    # folder exists
    sops.secrets = {
      samba_password.restartUnits = [ "samba-password.service" ];
    }
    // lib.genAttrs (map (u: "samba_password_${u}") cfg.saveUsers) (_: {
      restartUnits = [ "samba-password.service" ];
    });
    systemd.services.samba-password = {
      description = "Set Samba passwords from sops";
      wantedBy = [ "samba-smbd.service" ];
      before = [ "samba-smbd.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          setUser = u: secret: ''
            pw=$(cat ${config.sops.secrets.${secret}.path})
            printf '%s\n%s\n' "$pw" "$pw" | ${smbpasswd} -s -a ${u}
            if ${pkgs.util-linux}/bin/mountpoint -q /srv/data; then
              install -d -m 0755 -o ${u} -g users ${savesDir}/${u}
            fi
          '';
        in
        lib.concatStrings (
          [ (setUser user "samba_password") ] ++ map (u: setUser u "samba_password_${u}") cfg.saveUsers
        );
    };
  };
}
