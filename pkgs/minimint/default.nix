{ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl, clang, jq }:

rustPlatform.buildRustPackage rec {
  pname = "minimint";
  version = "master";
  nativeBuildInputs = [ pkg-config perl openssl clang jq ];
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
   src = builtins.fetchGit {
  url = "https://github.com/fedimint/minimint";
  ref = "master";
  };
  cargoSha256 = "sha256-74PC8hXAvk8PKPcOFwgkNRuJe+J6eE9I1WVirxnfjqw=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/minimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };
}