{ config, lib, pkgs, ... }:

with lib;
let
  options.services.fedimint-gateway = {
      enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable Fedimint-Gateway,connects fedimint and lightning network.
      '';
    }; 
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Webserver address";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Webserver port";
    };
    minimintCfg = mkOption {
      type = types.path;
      default = "/var/lib/minimint";
      description = "The data directory for minimint.";
    };
    user = mkOption {
      type = types.str;
      default = "clightning";
      description = "The user as which to run fedimint-gateway.";
    };
    group = mkOption {
      type = types.str;
      default = "clightning";
      description = "The group as which to run fedimint-gateway.";
    };
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.minimint;
      defaultText = "config.nix-bitcoin.pkgs.minimint";
      description = "The package providing minimint binaries.";
    };
  };

  cfg = config.services.fedimint-gateway;
  nbLib = config.nix-bitcoin.lib;
  nbPkgs = config.nix-bitcoin.pkgs;
  runAsUser = config.nix-bitcoin.runAsUserCmd;
  secretsDir = config.nix-bitcoin.secretsDir;
  bitcoind = config.services.bitcoind;

in {
  inherit options;
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.clightning.enable = true;
    services.clightning.extraConfig = ''
      plugin=${config.nix-bitcoin.pkgs.minimint}/bin/ln_gateway
      minimint-cfg=${cfg.minimintCfg}
    '';
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = {};
    nix-bitcoin.operator.groups = [ cfg.group ];
  };
}
