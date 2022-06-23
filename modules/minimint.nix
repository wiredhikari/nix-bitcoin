{ config, lib, pkgs, ... }:

with lib;
let
  options.services.minimint = {
    enable = mkEnableOption "Minimint, an implementation of a federated Chaumian bank";
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "HTTP server address.";
    };
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "HTTP server port.";
    };
    nodes = {
      clightning = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the clightning node interface.";
        };  
      };
    };  
  }
in {
  inherit options;

  config = mkIf cfg.enable {
    systemd.services.clightning = {};
  };
}
