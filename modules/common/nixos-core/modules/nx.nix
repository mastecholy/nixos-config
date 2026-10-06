{
  config,
  pkgs,
  configDirectory,
  ...
}:
let
  # One command for the usual flake workflow, run from any directory:
  #   nx                 pull, then switch
  #   nx test|boot       pull, then nh os test / boot
  #   nx sync [message]  pull, commit everything, switch, push if it built
  #   nx update          pull, update flake inputs, switch, commit + push flake.lock
  #   nx on <host>...    pull and switch on other hosts over SSH
  # Commits are GPG-signed, so sync/update only work where the key lives
  # (the workstations); servers just pull and switch.
  nx = pkgs.writeShellApplication {
    name = "nx";
    runtimeInputs = [
      pkgs.git
      pkgs.openssh
      config.programs.nh.package
    ];
    text = ''
      usage() {
        cat <<'HELP'
      nx                 pull, then switch
      nx test|boot       pull, then nh os test / boot
      nx sync [message]  pull, commit everything, switch, push if it built
      nx update          pull, update flake inputs, switch, commit + push flake.lock
      nx on <host>...    pull and switch on other hosts over SSH
      HELP
        exit "''${1:-0}"
      }

      cmd=''${1:-switch}
      [ $# -gt 0 ] && shift
      case $cmd in
        -h | --help | help) usage ;;
        switch | test | boot | sync | update | on) ;;
        *) usage 1 ;;
      esac
      cd ${configDirectory}

      pull() {
        echo ">>> git pull"
        git pull --rebase --autostash
      }

      case $cmd in
        switch | test | boot)
          pull
          nh os "$cmd" "$@"
          ;;
        sync)
          pull
          if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git status --short
            if [ $# -gt 0 ]; then git commit -m "$*"; else git commit; fi
          fi
          nh os switch
          echo ">>> git push"
          git push
          ;;
        update)
          pull
          nix flake update
          nh os switch
          if git diff --quiet flake.lock; then
            echo "Inputs already up to date"
          else
            git commit -m "flake: update inputs" flake.lock
            echo ">>> git push"
            git push
          fi
          ;;
        on)
          [ $# -gt 0 ] || usage 1
          # Deploy exactly what this machine has pushed: refuse if there are
          # unpushed commits, then put each host on this branch at this commit
          # (fast-forward only, so local changes over there stop it loudly)
          branch=$(git rev-parse --abbrev-ref HEAD)
          git fetch -q origin
          if [ -n "$(git log --oneline '@{u}..HEAD')" ]; then
            echo "This branch has commits that aren't pushed yet; push them (nx sync) first" >&2
            exit 1
          fi
          target=$(git rev-parse '@{u}')
          echo "Deploying $branch at $(git log -1 --format='%h %s' "$target")"

          # Spelled out rather than calling nx remotely, so it also works on a
          # host that doesn't have nx yet. -A forwards this machine's SSH agent
          # so the remote fetch authenticates to GitHub with the key that's
          # already unlocked here (the remote agent can't show a passphrase
          # prompt over a non-interactive SSH command)
          failed=()
          for host in "$@"; do
            echo ">>> $host"
            if ssh -A -t "$host" "cd ${configDirectory} && git fetch -q origin && git switch -q $branch && git merge -q --ff-only $target && nh os switch"; then
              echo ">>> $host: switched to $(git rev-parse --short "$target")"
            else
              failed+=("$host")
            fi
          done
          if [ ''${#failed[@]} -gt 0 ]; then
            echo "Failed on: ''${failed[*]}" >&2
            exit 1
          fi
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ nx ];
}
