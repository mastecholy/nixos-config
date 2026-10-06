{
  config,
  lib,
  users,
  ...
}:
let
  cfg = config.homelab.samba;
  user = users.primary.userName;
in
{
  options.homelab.samba.enable = lib.mkEnableOption "the data array as an SMB share (smb://nazgul/data)";

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
      };
    };

    # SMB only on the LAN and Tailscale
    networking.firewall.interfaces = lib.genAttrs [ config.homelab.lanInterface "tailscale0" ] (_: {
      allowedTCPPorts = [ 445 ];
    });

    # Samba keeps its own password database; keep the user's entry in sync
    # with the samba_password secret
    sops.secrets.samba_password.restartUnits = [ "samba-password.service" ];
    systemd.services.samba-password = {
      description = "Set ${user}'s Samba password from sops";
      wantedBy = [ "samba-smbd.service" ];
      before = [ "samba-smbd.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        pw=$(cat ${config.sops.secrets.samba_password.path})
        printf '%s\n%s\n' "$pw" "$pw" | ${config.services.samba.package}/bin/smbpasswd -s -a ${user}
      '';
    };
  };
}
