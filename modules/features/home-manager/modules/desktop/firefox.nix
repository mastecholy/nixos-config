{ userName, ... }:
{
  programs.firefox = {
    enable = true;
    profiles.${userName} = {
      id = 0;
      isDefault = true;
      extensions.force = true;
    };
  };

  stylix.targets.firefox = {
    enable = true;
    profileNames = [ userName ];
    colorTheme.enable = true;
    colors.enable = true;
  };
}
