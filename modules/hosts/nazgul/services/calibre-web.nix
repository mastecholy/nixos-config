{
  config,
  lib,
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

    # OPDS for the Kobo (KOReader), which isn't on Tailscale:
    # http://<nazgul's LAN IP>:8083/opds
    networking.firewall.interfaces.${cfg.lanInterface}.allowedTCPPorts = [ port ];
  };
}
