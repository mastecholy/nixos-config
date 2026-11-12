{
  config,
  lib,
  pkgs,
  ...
}:
let
  templates = ../../dotfiles/noctalia-templates;
  base16 = config.lib.stylix.colors.withHashtag;
  fonts = config.stylix.fonts;

  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.finalPackage "hyprctl";
  pkill = lib.getExe' pkgs.procps "pkill";

  # Qt apps take their colors from the palette file Noctalia's "qt" template
  # writes; Fusion is the built-in style that follows a custom palette
  qtctSettings = name: {
    Appearance = {
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/${name}/colors/noctalia.conf";
      style = "Fusion";
      standard_dialogs = "default";
    };
    Fonts = {
      fixed = ''"${fonts.monospace.name},${toString fonts.sizes.applications}"'';
      general = ''"${fonts.sansSerif.name},${toString fonts.sizes.applications}"'';
    };
  };

  gtkCss = ''
    @import url("noctalia.css");
  '';
in
{
  # Colors follow the wallpaper. Noctalia generates a Material palette from
  # the current wallpaper and renders it into each app's theme file whenever
  # the wallpaper changes (Super+W, the wallpaper widget, ...); apps that can
  # reload pick it up immediately.
  #
  # Stylix still provides fonts, cursor and opacity here, and its base16
  # scheme (modules/common/nixos-core/modules/stylix.nix) remains the static
  # theme for everything outside the desktop session: the TTY, the server,
  # and neovim until Noctalia has rendered a palette.
  #
  # The app configs are read-only (Home Manager), so each one includes or
  # selects Noctalia's generated file declaratively below instead of letting
  # Noctalia's templates edit them.

  # Stylix stops coloring what Noctalia colors now
  stylix.targets =
    lib.genAttrs
      [
        "bat"
        "btop"
        "fzf"
        "gtk"
        "hyprland"
        "kitty"
        "noctalia"
        "starship"
      ]
      (_: {
        colors.enable = false;
      })
    // {
      # Stylix's Qt theming is a Kvantum theme built from the scheme
      qt.enable = false;
    };

  programs.noctalia.settings.theme = {
    source = "wallpaper";
    # How strongly the palette follows the wallpaper: m3-content,
    # m3-tonal-spot, m3-fruit-salad, m3-rainbow or m3-monochrome
    wallpaper_scheme = "m3-content";

    templates = {
      # Shipped with Noctalia: noctalia theme --list-templates
      builtin_ids = [
        "btop"
        "gtk3"
        "gtk4"
        "qt"
      ];
      # Downloaded from Noctalia's template registry on first use.
      # pywalfox themes Firefox (see firefox.nix)
      community_ids = [
        "discord"
        "pywalfox"
      ];

      # Wallpaper palettes have no stable red, green, yellow...: their
      # terminal colors are all shades of the wallpaper. These take the
      # Stylix scheme's accents and tint them toward the wallpaper, so the
      # templates below get colors that still mean something in diffs,
      # prompts and syntax highlighting ({{colors.red.default.hex}}, ...)
      custom_colors = {
        red = base16.base08;
        orange = base16.base09;
        yellow = base16.base0A;
        green = base16.base0B;
        cyan = base16.base0C;
        blue = base16.base0D;
        magenta = base16.base0E;
      };

      # Own templates (../../dotfiles/noctalia-templates)
      user = {
        kitty = {
          input_path = "${templates}/kitty.conf";
          output_path = "$XDG_CONFIG_HOME/kitty/themes/noctalia.conf";
          # Running kitty windows reload their config on SIGUSR1
          post_hook = "${pkill} -USR1 kitty || true";
        };
        hyprland = {
          input_path = "${templates}/hyprland.lua";
          output_path = "$XDG_CONFIG_HOME/hypr/noctalia.lua";
          post_hook = "${hyprctl} reload";
        };
        # neovim watches this file and re-applies its colorscheme
        # (cli/neovim.nix)
        neovim = {
          input_path = "${templates}/base16.lua";
          output_path = "$XDG_CACHE_HOME/noctalia-theme/base16.lua";
        };
      };
    };
  };

  # Terminal: the generated theme replaces Stylix's include
  programs.kitty.extraConfig = ''
    include themes/noctalia.conf
  '';

  # Window borders, shadow and background. dofile (not require) so every
  # reload reads the file again; pcall because it doesn't exist until
  # Noctalia has rendered it once
  wayland.windowManager.hyprland.extraConfig = ''
    pcall(function()
      local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
      dofile(config_home .. "/hypr/noctalia.lua").apply_theme()
    end)
  '';

  programs.btop.settings.color_theme = "noctalia";

  # Terminal programs that had their own Stylix colors use the terminal's
  # 16 colors instead, so they follow kitty (starship already does)
  programs.bat.config.theme = "ansi";
  programs.fzf.defaultOptions = [ "--color=16" ];

  # GTK: adw-gtk3 recolored by the generated noctalia.css. GTK 4
  # (libadwaita) apps only need the css
  gtk = {
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    gtk4.theme = null;
  };
  xdg.configFile = {
    "gtk-3.0/gtk.css".text = gtkCss;
    "gtk-4.0/gtk.css".text = gtkCss;
  };

  # Qt: qt5ct/qt6ct with the generated palette (the system side sets
  # QT_QPA_PLATFORMTHEME, modules/features/workstation/modules/stylix.nix)
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings = qtctSettings "qt5ct";
    qt6ctSettings = qtctSettings "qt6ct";
  };
}
