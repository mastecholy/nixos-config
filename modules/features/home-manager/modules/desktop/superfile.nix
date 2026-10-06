{
  # superfile (terminal file manager, in kitty) as the default for folders,
  # e.g. "Show in folder" from Firefox or file pickers
  xdg.desktopEntries.superfile = {
    name = "superfile";
    genericName = "File Manager";
    exec = "kitty -e superfile %f";
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
    categories = [
      "System"
      "FileTools"
      "FileManager"
    ];
  };

  # Declaring defaults makes home-manager own ~/.config/mimeapps.list (any
  # existing one is kept as mimeapps.list.backup), so the browser defaults
  # are spelled out here too
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "superfile.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };
}
