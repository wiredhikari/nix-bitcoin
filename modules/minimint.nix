{ config, lib, pkgs, ... }:

with lib;
let
  options.services.minimint = {};

in {
  inherit options;

  config = mkIf cfg.enable {};
  }
