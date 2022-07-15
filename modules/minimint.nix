{ config, lib, pkgs, ... }:

with lib;
let
  options.services.minimint = {
      enable = mkOption {
      type = types.bool;
      default = true;
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
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/minimint";
      description = "The data directory for minimint.";
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
    tor.enforce = nbLib.tor.enforce;
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
    services.clightning.enable = true;
    systemd.services.minimint = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bitcoind.service" ];
      after = [ "bitcoind.service" ];
      serviceConfig = nbLib.defaultHardening // {
      WorkingDirectory = cfg.dataDir;
      ExecStart = ''
          ${config.nix-bitcoin.pkgs.minimint}/bin/minimint \
          --log-filters=INFO \
          --network=${bitcoind.makeNetworkName "bitcoin" "regtest"} \
          --db-dir='${cfg.dataDir}' \
          --daemon-dir='${bitcoind.dataDir}' \
          --electrum-rpc-addr=${cfg.address}:${toString cfg.port} \
          --daemon-rpc-addr=${nbLib.addressWithPort bitcoind.rpc.address bitcoind.rpc.port} \
          --daemon-p2p-addr=${nbLib.addressWithPort bitcoind.address bitcoind.whitelistedPort} \
      
      '';
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
##todo
# prestart and poststart setup
#