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

  users.users.${users.primary.userName}.openssh.authorizedKeys.keys = [
    users.primary.sshKey
  ]
  ++ users.primary.extraAuthorizedKeys;
}
