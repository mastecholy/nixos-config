{ pkgs, ... }:
let
  # Always-on host on the LAN that sends the magic packets; other hosts ask it
  # over SSH, so this works from anywhere on Tailscale
  relay = "nazgul";
  # "<host> <mac>" per line, declared on the relay (modules/hosts/nazgul/wol.nix)
  macs = "/run/secrets/wol_hosts";

  wake = pkgs.writeShellApplication {
    name = "wake";
    runtimeInputs = with pkgs; [
      gawk
      openssh
      wakeonlan
    ];
    text = ''
      send_only=0
      if [ "''${1:-}" = --send-only ]; then
        send_only=1
        shift
      fi
      host=''${1:?usage: wake <host>}

      if [ "$(uname -n)" = ${relay} ]; then
        mac=$(awk -v h="$host" '$1 == h { print $2 }' ${macs})
        if [ -z "$mac" ]; then
          echo "No MAC address for $host in the wol_hosts secret" >&2
          exit 1
        fi
        wakeonlan "$mac"
      else
        ssh ${relay} wake --send-only "$host"
      fi
      [ $send_only = 1 ] && exit 0

      echo "Waiting for $host to come up..."
      for _ in $(seq 120); do
        if ping -c1 -W1 "$host" >/dev/null 2>&1; then
          echo "$host is up"
          exit 0
        fi
      done
      echo "$host didn't answer within 2 minutes" >&2
      exit 1
    '';
  };
in
{
  environment.systemPackages = [ wake ];
}
