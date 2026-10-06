{ config, users, ... }:
let
  user = users.primary.userName;
  mountPoint = "/mnt/nazgul";
in
{
  # nazgul's data array (smb://nazgul/data), mounted on first access and
  # unmounted after 10 idle minutes. Logs in with the samba_password secret,
  # so there's nothing to type or remember. ~/nazgul links to it.
  sops.secrets.samba_password = { };
  sops.templates."nazgul-smb-credentials".content = ''
    username=${user}
    password=${config.sops.placeholder.samba_password}
  '';

  fileSystems.${mountPoint} = {
    device = "//nazgul/data";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."nazgul-smb-credentials".path}"
      "uid=${toString config.users.users.${user}.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "vers=3.1.1"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.mount-timeout=10s"
      # "nazgul" resolves through Tailscale's MagicDNS
      "x-systemd.after=tailscaled.service"
    ];
  };

  systemd.tmpfiles.rules = [
    "L+ /home/${user}/nazgul - - - - ${mountPoint}"
  ];
}
