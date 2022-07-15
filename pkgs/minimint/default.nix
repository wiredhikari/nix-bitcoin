{ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl }:

rustPlatform.buildRustPackage rec {
  pname = "minimint";
  version = "master";

  nativeBuildInputs = [ pkg-config perl openssl  ];
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
  src = builtins.fetchGit {
  url = "https://github.com/fedimint/minimint";
  ref = "master";
  };


  cargoSha256 =  "sha256-6TFiDFqP888qxWLAlyvofa/NFr+2hU8R0HvdHtqkGeg=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/minimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };

}