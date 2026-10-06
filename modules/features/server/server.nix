{ inputs, ... }:
{
  # Headless server: core plus whatever ./modules adds, no desktop
  imports = [
    (inputs.import-tree ./modules)
  ];
}
