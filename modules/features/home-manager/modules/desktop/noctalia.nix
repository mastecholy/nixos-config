{
  config,
  lib,
  pkgs,
  osConfig,
  hostName,
  ...
}:
let
  # Seconds to wait before running a power action; selecting it again runs it
  # immediately, Escape or moving to another entry cancels
  countdown = 10;

  font = "Liberation Mono";

  # Per-host UI scale (the laptop panel is HiDPI)
  uiScale = { sihil = 1.5; }.${hostName} or 1.0;

  wallpapers = "${config.home.homeDirectory}/Pictures/Wallpapers";
in
{
  home.packages = [ pkgs.liberation_ttf ];

  # Noctalia merges every *.toml in its config dir; this one holds the
  # location, decrypted from secrets/secrets.yaml
  xdg.configFile."noctalia/private.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      osConfig.sops.templates."noctalia-private.toml".path;

  # Writes the base config to ~/.config/noctalia/config.toml (validated at
  # build time). Noctalia itself runs from the NixOS module's systemd service.
  # Changes made in Noctalia's settings window are saved to
  # ~/.local/state/noctalia/settings.toml and layered on top of this file;
  # delete that file to fall back to exactly what's declared here.
  #
  # Colors, dark/light mode and popup opacity come from stylix
  # (stylix.targets.noctalia), so Noctalia's own hyprland/kitty/qt templates
  # are left off to avoid fighting stylix over those files.
  programs.noctalia = {
    enable = true;
    settings = {
      accessibility.ui_scale = uiScale;

      audio.enable_overdrive = true;

      bar.default = {
        start = [
          "wallpaper"
          "workspaces"
          "active_window"
        ];
        center = [
          "cat"
          "clock"
          "spacer_2"
          "control-center"
        ];
        end = [
          "media"
          "weather"
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "session"
        ];
        border_width = 1.5;
        capsule_thickness = 0.77;
        color = "on_surface";
        concave_edge_corners = false;
        font_family = font;
        font_scale = 1.23;
        margin_ends = 0;
        padding = 29;
        scale = 1.25;
        thickness = 50;
        widget_spacing = 20;
      };

      # Lock after 10 min, screen off at 11, suspend at 15
      idle = {
        behavior_order = [
          "lock"
          "screen-off"
          "lock-and-suspend"
        ];
        behavior = {
          lock = {
            action = "lock";
            enabled = true;
            timeout = 600.0;
          };
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = 660.0;
          };
          lock-and-suspend = {
            action = "lock_and_suspend";
            enabled = true;
            timeout = 900.0;
          };
        };
      };

      # Downloaded by Noctalia from its plugin registry on first start
      plugins.enabled = [ "noctalia/bongocat" ];

      # gothmog's keyboard shows up as several input devices with differing
      # Num Lock state, so every keypress flashed a Num Lock popup
      osd.kinds.lock_keys = hostName != "gothmog";

      control_center = {
        sidebar = "full";
        sidebar_section = "full";
        width = 890;
      };

      shell = {
        # Overrides stylix's sans-serif font for the shell
        font_family = lib.mkForce font;
        panel.transparency_mode = "soft";
        screenshot.confirm_region = true;

        session.actions = [
          {
            action = "lock";
            shortcut = "1";
          }
          {
            action = "logout";
            shortcut = "2";
            countdown_seconds = countdown;
          }
          {
            action = "lock_and_suspend";
            shortcut = "3";
            countdown_seconds = countdown;
          }
          {
            action = "reboot";
            shortcut = "4";
            countdown_seconds = countdown;
          }
          {
            action = "shutdown";
            shortcut = "5";
            variant = "destructive";
            countdown_seconds = countdown;
          }
        ];
      };

      theme.templates.community_ids = [ "discord" ];

      wallpaper = {
        directory = wallpapers;
        automation.recursive = true;
        default.path = "${wallpapers}/Knight of the void Patreon.jpg";
      };

      weather.unit = "imperial";

      widget = {
        battery.show_label = false;
        brightness.show_label = false;

        # Keyboard devices are per machine, so input_devices is set in
        # Noctalia's settings window (~/.local/state/noctalia/settings.toml)
        cat.type = "noctalia/bongocat:cat";
        clock.anchor = true;

        media.hide_when_no_media = true;
        weather = {
          font_scale = 0.9;
          show_condition = false;
        };
        network.show_label = false;
        volume.show_label = false;
        spacer_2 = {
          type = "spacer";
          length = 8;
        };
      };
    };
  };
}
