{
  lib,
  pkgs,
  hasNvidia ? false,
  nvidiaPrime ? false,
  hostName,
  ...
}:

{
  home.packages = [ pkgs.wl-clipboard ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    extraLuaFiles = {

      # Only for NVIDIA-primary systems; on PRIME offload laptops Hyprland
      # runs on the iGPU and these would force everything onto the dGPU.
      "hyprland.nvidia_env" = {
        content = lib.optionalString (hasNvidia && !nvidiaPrime) ''
          hl.env("LIBVA_DRIVER_NAME", "nvidia")
          hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
          hl.env("GBM_BACKEND", "nvidia-drm")
        '';
        autoLoad = true;
      };

      "hyprland.config" = {
        content = ../../dotfiles/hypr/config.lua;
        autoLoad = true;
      };
      "hyprland.rules" = {
        content = ../../dotfiles/hypr/rules.lua;
        autoLoad = true;
      };
      "hyprland.curves" = {
        content = ../../dotfiles/hypr/curves.lua;
        autoLoad = true;
      };
      "hyprland.animations" = {
        content = ../../dotfiles/hypr/animations.lua;
        autoLoad = true;
      };
      # Per-host monitor layout and workspace placement
      "hyprland.monitors" = {
        content = ../../../../hosts + "/${hostName}/monitors.lua";
        autoLoad = true;
      };
      "hyprland.gestures" = {
        content = ../../dotfiles/hypr/gestures.lua;
        autoLoad = true;
      };
      "lib.keys" = {
        content = ../../dotfiles/hypr/keys.lua;
        autoLoad = false;
      };
      "lib.helpers" = {
        content = ../../dotfiles/hypr/helpers.lua;
        autoLoad = false;
      };
      "hyprland.keys" = {
        content = ''
          require("hyprland.hotkeys.applications")
          require("hyprland.hotkeys.noctalia")
          require("hyprland.hotkeys.windows")
          require("hyprland.hotkeys.workspaces")
          require("hyprland.hotkeys.submaps")
          require("hyprland.hotkeys.navigation")
        '';
        autoLoad = true;
      };
      "hyprland.hotkeys.applications" = {
        content = ../../dotfiles/hypr/applications.lua;
        autoLoad = false;
      };
      "hyprland.hotkeys.noctalia" = {
        content = ../../dotfiles/hypr/noctalia.lua;
        autoLoad = false;
      };
      "hyprland.hotkeys.windows" = {
        content = ../../dotfiles/hypr/windows.lua;
        autoLoad = false;
      };
      "hyprland.hotkeys.workspaces" = {
        content = ../../dotfiles/hypr/workspaces.lua;
        autoLoad = false;
      };
      "hyprland.hotkeys.submaps" = {
        content = ../../dotfiles/hypr/submaps.lua;
        autoLoad = false;
      };
      "hyprland.hotkeys.navigation" = {
        content = ../../dotfiles/hypr/navigation.lua;
        autoLoad = false;
      };
    };
  };
}
