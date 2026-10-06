{
  users,
  lib,
  pkgs,
  ...
}:
{
  # Password hashes come from sops, see ./secrets.nix
  users = {
    mutableUsers = lib.mkDefault false;
    users = {
      ${users.primary.userName} = {
        isNormalUser = true;
        # Fixed so file ownership matches across hosts and shared data disks
        uid = 1000;
        shell = pkgs.fish;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };
    };
  };
}
