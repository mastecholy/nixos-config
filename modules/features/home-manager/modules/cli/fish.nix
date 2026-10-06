{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      microfetch
    '';
    plugins = [
      {
        name = "autopair";
        inherit (pkgs.fishPlugins.autopair) src;
      }
    ];
    shellAbbrs = {
      cdn = "cd /etc/nixos";
      g = "git";
      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gp = "git push";
      nrs = "nh os switch";
      nrt = "nh os test";
      nrb = "nh os boot";
      nfu = "nix flake update";
      spf = "superfile";
    };
    functions.clh.body = ''
      echo yes | history clear
      clear && fish
    '';
  };

  # Prompt; colors come from stylix's base16 palette
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch = {
        symbol = " ";
        style = "purple";
        format = "[$symbol$branch]($style) ";
      };
      git_status.style = "red";
      nix_shell = {
        symbol = " ";
        style = "cyan";
        format = "[$symbol$state( \\($name\\))]($style) ";
      };
      cmd_duration = {
        min_time = 2000;
        style = "yellow";
        format = "[ $duration]($style) ";
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };

  programs.bat.enable = true;

  # Ctrl-R history search, Ctrl-T file search, Alt-C cd
  programs.fzf.enable = true;

  # `z <partial-dir>` jumps to frequently used directories
  programs.zoxide.enable = true;
}
