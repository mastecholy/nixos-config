{ users, ... }:
{
  # MAC addresses for `wake <host>` (modules/common/nixos-core/modules/wake.nix),
  # one "<host> <mac>" per line
  sops.secrets.wol_hosts.owner = users.primary.userName;
}
