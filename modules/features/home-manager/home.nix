{
  lib,
  inputs,
  stateVersion,
  userName,
  role,
  ...
}:
{
  # cli/: shell, editor, git and ssh on every host
  # desktop/: Hyprland, Noctalia, kitty and Firefox on workstations only
  imports = [
    inputs.lazyvim.homeManagerModules.default
    (inputs.import-tree ./modules/cli)
  ]
  ++ lib.optional (role == "workstation") (inputs.import-tree ./modules/desktop);

  programs.home-manager.enable = true;
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    inherit stateVersion;
  };
}
