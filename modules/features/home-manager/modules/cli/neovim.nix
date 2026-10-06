{ config, pkgs, ... }:
let
  palette = builtins.concatStringsSep ", " (
    map (n: "${n} = '${config.lib.stylix.colors.withHashtag.${n}}'") [
      "base00"
      "base01"
      "base02"
      "base03"
      "base04"
      "base05"
      "base06"
      "base07"
      "base08"
      "base09"
      "base0A"
      "base0B"
      "base0C"
      "base0D"
      "base0E"
      "base0F"
    ]
  );
in
{
  # LazyVim ships lualine, bufferline, which-key, gitsigns, snacks (picker,
  # explorer, dashboard), treesitter, LSP and completion out of the box.
  programs.lazyvim = {
    enable = true;

    extras = {
      lang.nix.enable = true;
      lang.json.enable = true;
      lang.markdown.enable = true;
      lang.toml.enable = true;
      lang.yaml.enable = true;
      coding.mini-surround.enable = true;
      editor.mini-files.enable = true;
      ui.indent-blankline.enable = true;
    };

    # Language servers, linters and formatters the extras above call
    extraPackages = with pkgs; [
      nil # nix LSP
      statix # nix linter
      nixfmt # nix formatter
      vscode-langservers-extracted # jsonls
      marksman # markdown LSP
      markdownlint-cli2 # markdown linter
      taplo # toml LSP/formatter
      yaml-language-server
    ];

    config.options = ''
      -- Narrower line-number column (it still grows to fit longer numbers)
      vim.opt.numberwidth = 2
    '';

    # Colorscheme generated from the stylix base16 palette, so neovim follows
    # whatever scheme stylix is set to
    plugins.colorscheme = ''
      return {
        { dir = "${pkgs.vimPlugins.mini-base16}", name = "mini.base16", lazy = false, priority = 1000 },
        {
          "LazyVim/LazyVim",
          opts = {
            colorscheme = function()
              require("mini.base16").setup({ palette = { ${palette} } })
              vim.g.colors_name = "stylix"
            end,
          },
        },
      }
    '';
  };

  # Stylix's own neovim target loads its plugin outside lazy.nvim, where
  # LazyVim's colorscheme would override it; the spec above replaces it
  stylix.targets.neovim.enable = false;
}
