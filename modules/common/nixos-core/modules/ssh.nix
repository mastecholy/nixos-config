{ users, ... }:
{
  # Key-only SSH for the primary user, reachable over Tailscale only
  services.openssh = {
    enable = true;
    # Don't open port 22 on every interface; see the tailscale0 rule below
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ users.primary.userName ];
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # GitHub's published host key, so git over SSH works on a fresh machine
  # without a "trust this host?" prompt (which non-interactive SSH can't show)
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  users.users.${users.primary.userName}.openssh.authorizedKeys.keys = [
    users.primary.sshKey
  ]
  ++ users.primary.extraAuthorizedKeys;
}
