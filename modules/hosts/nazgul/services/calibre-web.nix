{
  config,
  lib,
  pkgs,
  users,
  ...
}:
let
  cfg = config.homelab;
  port = 8083;
in
{
  options.homelab.calibreWeb.enable = lib.mkEnableOption "Calibre-Web (native service)";

  config = lib.mkIf cfg.calibreWeb.enable {
    # Ebook library (a Calibre library: Author/Title (id)/Title - Author.epub
    # plus metadata.db) with a web UI at books.<domain> and an OPDS feed at
    # /opds for KOReader. Runs as the primary user so it can edit the library
    # files, which belong to you.
    services.calibre-web = {
      enable = true;
      # Kobo sync (Admin → Edit Basic Configuration → Feature Configuration)
      # only shows up when its optional dependency is installed
      package = pkgs.calibre-web.overridePythonAttrs (old: {
        dependencies = old.dependencies ++ old.optional-dependencies.kobo;
      });
      user = users.primary.userName;
      group = "users";
      listen = {
        ip = "0.0.0.0";
        inherit port;
      };
      options = {
        calibreLibrary = "${cfg.media}/library/books";
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };

    # Kobo sync sends kepubs, which the stock Kobo reader handles best.
    # Calibre-Web only accepts a kepubify named like the upstream release
    # (kepubify-linux-64bit), so enableKepubify's bin/kepubify is refused;
    # point it at a folder with that name instead, after the module's own
    # settings are written
    systemd.services.calibre-web.serviceConfig.ExecStartPre =
      let
        kepubifyDir = pkgs.runCommand "kepubify-calibre-web" { } ''
          mkdir $out
          ln -s ${lib.getExe pkgs.kepubify} $out/kepubify-linux-64bit
        '';
      in
      lib.mkAfter [
        (pkgs.writeShellScript "calibre-web-kepubify" ''
          ${lib.getExe pkgs.sqlite} /var/lib/calibre-web/app.db \
            "update settings set config_kepubifypath = '${kepubifyDir}'"
        '')
      ];

    # The Kobo isn't on Tailscale, so it reaches Calibre-Web on the LAN:
    # OPDS for KOReader at http://<nazgul's LAN IP>:8083/opds, Kobo sync at
    # the api_endpoint from Calibre-Web's user settings
    networking.firewall.interfaces.${cfg.lanInterface}.allowedTCPPorts = [ port ];
  };
}
