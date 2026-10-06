{
  gpgKey,
  osConfig,
  ...
}:
{
  programs.git = {
    enable = true;
    signing = {
      key = gpgKey;
      format = "openpgp";
      signByDefault = true;
      signer = "/run/current-system/sw/bin/gpg2";
    };
    # user.name and user.email, decrypted from secrets/secrets.yaml
    includes = [
      { inherit (osConfig.sops.templates.git-identity) path; }
      # This config is public: commit to it under the GitHub username and
      # no-reply address instead of the real name and email above
      {
        condition = "gitdir:/etc/nixos/";
        contents.user = {
          name = "mastecholy";
          email = "93687565+mastecholy@users.noreply.github.com";
        };
      }
    ];
    settings = {
      init = {
        defaultBranch = "main";
      };
      user = {
        # Refuse to commit if the identity above is missing
        useConfigOnly = true;
      };
      credential = {
        "https://github.com" = {
          helper = "/run/current-system/sw/bin/gh auth git-credential";
        };
        "https://gist.github.com" = {
          helper = "/run/current-system/sw/bin/gh auth git-credential";
        };
      };
    };
  };
}
