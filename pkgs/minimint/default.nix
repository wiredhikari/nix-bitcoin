{ lib, rustPlatform, fetchFromGitHub, openssl, pkg-config, perl}:

rustPlatform.buildRustPackage rec {
  pname = "minimint";
  version = "master";

  checkType = "debug";
  src = builtins.fetchGit {
  url = "https://github.com/fedimint/minimint";
  ref = "master";
  };
  buildInputs = [
    openssl
    pkg-config
    perl
  ];

  cargoSha256 =  "sha256-TmdL8rJtO8Y04LeXf8XOJf3AjLEOgiWneCD5JaQSFQc=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/minimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };
}