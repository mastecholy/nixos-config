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

    # Colorscheme from a base16 palette. On the workstations Noctalia
    # renders one from the wallpaper (desktop/theme.nix) and neovim re-applies
    # it whenever that file changes; without it (the server, or before the
    # first render) the stylix scheme is used
    plugins.colorscheme = ''
      local static = { ${palette} }
      local dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/noctalia-theme"
      local name = "base16.lua"

      local function apply(startup)
        local ok, dynamic = pcall(dofile, dir .. "/" .. name)
        if not (ok and type(dynamic) == "table") then
          -- Missing or half-written file: keep what's shown, unless nothing is yet
          if not startup then return end
          dynamic = static
        end
        require("mini.base16").setup({ palette = dynamic })
        vim.g.colors_name = "stylix"
        if not startup then
          -- Let statusline and other plugins rebuild their colors
          vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "stylix" })
        end
      end

      return {
        { dir = "${pkgs.vimPlugins.mini-base16}", name = "mini.base16", lazy = false, priority = 1000 },
        {
          "LazyVim/LazyVim",
          opts = {
            colorscheme = function()
              apply(true)
              if vim.uv.fs_stat(dir) then
                local timer = assert(vim.uv.new_timer())
                local watcher = assert(vim.uv.new_fs_event())
                watcher:start(dir, {}, function(_, changed)
                  if changed == name then
                    -- A write shows up as several events; wait for it to settle
                    timer:stop()
                    timer:start(150, 0, vim.schedule_wrap(function() apply(false) end))
                  end
                end)
              end
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
