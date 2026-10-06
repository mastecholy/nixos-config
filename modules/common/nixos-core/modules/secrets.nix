{ config, users, ... }:
let
  user = users.primary.userName;
  inherit (config.sops) placeholder;
in
{
  sops = {
    # Encrypted with sops; recipients are listed in /.sops.yaml. Each host
    # decrypts with its SSH host key (/etc/ssh/ssh_host_ed25519_key).
    defaultSopsFile = ../../../../secrets/secrets.yaml;

    secrets = {
      # Decrypted before users are created, see users.users below
      root_password_hash.neededForUsers = true;
      user_password_hash.neededForUsers = true;

      full_name = { };
      email = { };
      location = { };
      ssh_hosts = { };
    };

    # Files rendered at activation under /run/secrets/rendered/ and included
    # by the apps that need them (see the home-manager git, ssh and noctalia
    # modules)
    templates = {
      git-identity = {
        owner = user;
        content = ''
          [user]
            name = ${placeholder.full_name}
            email = ${placeholder.email}
        '';
      };

      ssh-hosts = {
        owner = user;
        content = placeholder.ssh_hosts;
      };

      "noctalia-private.toml" = {
        owner = user;
        content = ''
          [location]
          address = "${placeholder.location}"
        '';
      };
    };
  };

  users.users = {
    root.hashedPasswordFile = config.sops.secrets.root_password_hash.path;
    ${user}.hashedPasswordFile = config.sops.secrets.user_password_hash.path;
  };
}
