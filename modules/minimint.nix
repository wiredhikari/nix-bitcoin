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
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.minimint;
      defaultText = "config.nix-bitcoin.pkgs.minimint";
      description = "The package providing minimint binaries.";
    };
  };

  cfg = config.services.minimint;
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
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0770 ${cfg.user} ${cfg.group} - -"
    ];
    systemd.services.minimint = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bitcoind.service" ];
      after = [ "bitcoind.service" ];
      preStart = ''
        echo "auth = \"${bitcoind.rpc.users.public.name}:$(cat ${secretsDir}/bitcoin-rpcpassword-public)\"" \
          > minimint.toml
      '';
      serviceConfig = nbLib.defaultHardening // {
      WorkingDirectory = cfg.dataDir;
      ExecStart = ''
          set -euxo pipefail
          cd $FM_CFG_DIR
          for ((ID=SKIPPED_SERVERS; ID<FM_FED_SIZE; ID++)); do
            echo "starting mint $ID"
            ( ($FM_BIN_DIR/server $FM_CFG_DIR/server-$ID.json 2>&1 & echo $! >&3 ) 3>>$FM_PID_FILE | sed -e "s/^/mint $ID: /" ) &
          done          
          ${nbPkgs.minimint}/build/source/minimint \
          --log-filters=INFO \
          --network=${bitcoind.makeNetworkName "bitcoin" "regtest"} \
          --db-dir='${cfg.dataDir}' \
          --electrum-rpc-addr=${cfg.address}:${toString cfg.port} \
          --daemon-rpc-addr=${nbLib.addressWithPort bitcoind.rpc.address bitcoind.rpc.port} \
          --daemon-p2p-addr=${nbLib.addressWithPort bitcoind.address bitcoind.whitelistedPort} \
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
