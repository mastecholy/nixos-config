{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      # Hardlink identical files as they're added to the store, instead of
      # a scheduled optimise job
      auto-optimise-store = true;
    };
  };
}
