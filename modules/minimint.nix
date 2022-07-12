{ config, lib, pkgs, ... }:

with lib;
let
  options.services.minimint = {
      enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Minimint,is a federated Chaumian e-cash mint backed 
        by bitcoin with deposits and withdrawals that can occur on-chain
        or via Lightning.
      '';
    }; 
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen for RPC connections.";
    };
    port = mkOption {
      type = types.port;
      default = 5001;
      description = "Port to listen for RPC connections.";
    };
    user = mkOption {
      type = types.str;
      default = "minimint";
      description = "The user as which to run minimint.";
    };
    group = mkOption {
      type = types.str;
      default = cfg.user;
      description = "The group as which to run minimint.";
    };
    nodes = {
      clightning = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the clightning node interface.";
        };  
      };
    };  
  };

  cfg = config.services.minimint;
  nbLib = config.nix-bitcoin.lib;
  secretsDir = config.nix-bitcoin.secretsDir;
  bitcoind = config.services.bitcoind;

in {
  inherit options;
  config = mkIf cfg.enable {
    services.bitcoind = {
      enable = true;
      txindex = true;
    };
    services.lnd.enable = true;

    systemd.services.minimint = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bitcoind.service" ];
      after = [ "bitcoind.service" ];
      serviceConfig = nbLib.defaultHardening // {
      User = cfg.user;
      Group = cfg.group;
      Restart = "on-failure";
      RestartSec = "10s";
      };
    };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "bitcoinrpc-public" ];
    };
    users.groups.${cfg.group} = {};
  };
}
