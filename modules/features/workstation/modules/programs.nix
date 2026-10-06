{ pkgs, users, ... }:
{
  users.users.${users.primary.userName}.extraGroups = [ "input" ];

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = false;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # The stock package already supports NVENC and comes from the binary
    # cache; overriding cudaSupport forced a local rebuild on every update
    obs-studio.enable = true;

    # Lets bongocat (Noctalia) read keyboard events from /dev/input.
    # Note: any program running as this user can then read all keystrokes

    noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
    };

    # AirDrop-style transfers to phones and other computers on the network
    localsend.enable = true;

    gnupg.agent = {
      pinentryPackage = pkgs.pinentry-gnome3;
      settings = {
        default-cache-ttl = 43200;
        max-cache-ttl = 43200;
      };
    };

  };

  environment.systemPackages = with pkgs; [
    discord
    ytmdesktop
    # Inspect input devices: sudo evtest
    evtest
    # Editing secrets/secrets.yaml and adding host keys
    sops
    age
    ssh-to-age
  ];

}
