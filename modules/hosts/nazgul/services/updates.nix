{
  config,
  lib,
  pkgs,
  ...
}:
let
  docker = "${config.virtualisation.docker.package}/bin/docker";
  tracked = lib.getAttrs config.homelab.containerUpdates config.virtualisation.oci-containers.containers;
in
{
  # Containers that follow a moving tag (Immich v3, gluetun v3, qBittorrent
  # latest) list themselves here. They start from the local image and are
  # only pulled by this weekly job: pulling on every start made them fail
  # at boot, before DNS works, and systemd then gave up on them
  options.homelab.containerUpdates = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "oci-containers to pull and restart weekly when their image changes.";
  };

  # Native services (Jellyfin, Audiobookshelf, Calibre-Web, Komga, File
  # Browser) update with nixpkgs: `nx update` on a workstation, then
  # `nx on nazgul`. Containers update here instead: once a week, pull each
  # tracked image and restart only the containers whose image changed.
  config.systemd.services.container-updates = lib.mkIf (tracked != { }) {
    description = "Pull newer container images and restart changed containers";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.systemd ];
    script = lib.concatStrings (
      lib.mapAttrsToList (name: c: ''
        before=$(${docker} image inspect -f '{{.Id}}' ${lib.escapeShellArg c.image} 2>/dev/null || true)
        if ${docker} pull -q ${lib.escapeShellArg c.image} >/dev/null; then
          after=$(${docker} image inspect -f '{{.Id}}' ${lib.escapeShellArg c.image})
          if [ "$before" != "$after" ]; then
            echo "${name}: new image, restarting"
            systemctl restart docker-${name}.service
          else
            echo "${name}: up to date"
          fi
        else
          echo "${name}: pull failed, left running" >&2
        fi
      '') tracked
    );
  };

  config.systemd.timers.container-updates = lib.mkIf (tracked != { }) {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 04:00";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
  };
}
