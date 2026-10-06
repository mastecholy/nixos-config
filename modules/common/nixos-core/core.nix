{
  inputs,
  pkgs,
  configDirectory,
  timeZone,
  stateVersion,
  ...
}:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    (inputs.import-tree ./modules)
  ];

  time = { inherit timeZone; };
  nixpkgs.config.allowUnfree = true;
  system = { inherit stateVersion; };

  services.dbus.enable = true;
  services.envfs.enable = true;

  services.tailscale = {
    enable = true;
  };

  programs = {
    gnupg = {
      agent.enable = true;
      agent.enableSSHSupport = true;
    };

    fish.enable = true;
  };
  environment = {
    sessionVariables = {
      CONFIG = configDirectory;
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs; [
      nix-output-monitor
      ripgrep
      rsync
      tmux
      # Lets programs over SSH from kitty (TERM=xterm-kitty) draw correctly
      kitty.terminfo
      _7zz
      zip
      eza
      bat
      unzip
      git
      gh
      neovim
      devenv
      microfetch
      tree
      superfile
      yazi
    ];
  };
}
