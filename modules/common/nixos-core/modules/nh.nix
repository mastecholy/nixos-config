{ lib, configDirectory, ... }: {
  programs.nh = lib.mkDefault {
    enable = true;
    flake = configDirectory;
    # Weekly cleanup of old generations; keeps enough history to roll back
    # an update whose problems only show up a week or so later
    clean = {
      enable = true;
      dates = "Mon *-*-* 09:00:00";
      extraArgs = "--keep 5 --keep-since 14d";
    };
  };
}
