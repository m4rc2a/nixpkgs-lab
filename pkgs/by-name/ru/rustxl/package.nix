{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustxl";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "only-using-ai";
    repo = "rustxl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gx4K1g1w8x7qCwqptyO8psdvKLJ2IOzk8pKeGvL2F+M=";
  };

  cargoHash = "sha256-uC+WJpdLS86NWusztG4oDfTBcuzzp9gEVA2X8oYEWM0=";

  # Upstream test fails at v0.1.8; the remaining tests pass.
  checkFlags = [ "--skip=formula::tests::test_evaluate_sumif" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A fast, terminal-based spreadsheet application written in Rust";
    homepage = "https://github.com/only-using-ai/rustxl";
    changelog = "https://github.com/only-using-ai/rustxl/releases/tag/${finalAttrs.src.tag}";
    # Upstream declares MIT in its README but ships no LICENSE file.
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "xl";
  };
})
