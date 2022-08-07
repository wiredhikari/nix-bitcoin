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
      description = "The data directory for fedimint-gateway.";
    };
    user = mkOption {
      type = types.str;
      default = "fedimint-gateway";
      description = "The user as which to run fedimint-gateway.";
    };
    group = mkOption {
      type = types.str;
      default = cfg.user;
      description = "The group as which to run fedimint-gateway.";
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
    services.bitcoind = {
      enable = true;
      txindex = true;
    };
    services.clightning.enable = true;
  
    systemd.services.fedimint-gateway = {
      wantedBy = [ "minimint.service" "multi-user.target" ];
      requires = [ "clightning.service" ];
      after = [ "clightning.service" ];

      preStart = ''
        echo "auth = \"${bitcoind.rpc.users.public.name}:$(cat ${secretsDir}/bitcoin-rpcpassword-public)\"" \
          > fedimint-gateway.toml
        macaroonDir=/var/lib/minimint/ln
        mkdir -p $macaroonDir
      '';



      serviceConfig = nbLib.defaultHardening // {
      WorkingDirectory = cfg.dataDir;
      ExecStart = ''
        lightningd --network regtest --bitcoin-rpcuser=root --bitcoin-rpcpassword= --lightning-dir=/var/lib/minimint --addr=127.0.0.1:9736 --plugin=ln_gateway --minimint-cfg=/var/lib/minimint/client.json
      '';
      User = cfg.user;
      Group = cfg.group;
      Restart = "on-failure";
      RestartSec = "10s";
      ReadWritePaths = cfg.dataDir;
      };
    };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "bitcoinrpc-public" ];
    };
    users.groups.${cfg.group} = {};
    nix-bitcoin.operator.groups = [ cfg.group ];
  };
}
