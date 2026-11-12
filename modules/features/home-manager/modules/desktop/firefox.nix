{ userName, ... }:
{
  programs.firefox = {
    enable = true;
    profiles.${userName} = {
      id = 0;
      isDefault = true;
    };

    # Colors follow the wallpaper through the Pywalfox extension: Noctalia's
    # pywalfox template (./theme.nix) pushes each new palette to it. After
    # the first deploy, restart Firefox once so it finds Noctalia's
    # native-messaging host
    policies.ExtensionSettings."pywalfox@frewacom.org" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
    };
  };

  # Fonts only; colors come from Pywalfox
  stylix.targets.firefox = {
    enable = true;
    profileNames = [ userName ];
    colors.enable = false;
  };
}
