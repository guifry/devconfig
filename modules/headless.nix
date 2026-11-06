{ lib, ... }:

{
  options.headless = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Headless server mode: omit desktop-only packages and clipboard integrations.";
  };
}
