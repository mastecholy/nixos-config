{ users, ... }:
{
  # Backend for virtualisation.oci-containers; containers are declared per
  # host (e.g. modules/hosts/nazgul/services) and run as docker-<name> units
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Lets the primary user run docker without sudo. Note: docker group access
  # is equivalent to root on this machine.
  users.users.${users.primary.userName}.extraGroups = [ "docker" ];
}
