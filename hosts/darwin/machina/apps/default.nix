{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    qmk
  ];

  homebrew = {
    casks = [
      "autodesk-fusion"
      "elgato-stream-deck"
      "orcaslicer@nightly"
      "paintbrush"
      "via"
    ];
  };
}
