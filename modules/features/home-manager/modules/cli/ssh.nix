{
  osConfig,
  ...
}:
{
  # Each machine has its own ~/.ssh/id_ed25519 key pair (ssh-keygen); add
  # its public key to extraAuthorizedKeys in flake.nix to allow logins.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Private hosts, decrypted from secrets/secrets.yaml (ssh_hosts)
    includes = [ osConfig.sops.templates.ssh-hosts.path ];
    settings = {
      # Hand keys to the agent (gpg-agent) on first use so the passphrase is
      # asked once per session instead of on every connection
      "*".AddKeysToAgent = "yes";

      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Own machines, reached over Tailscale MagicDNS
      "sihil gothmog nazgul" = {
        User = "mas";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
