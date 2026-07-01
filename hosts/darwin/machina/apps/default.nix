{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    qmk
  ];

  homebrew = {
    brews = [
      "m1ddc"
    ];

    casks = [
      "autodesk-fusion"
      "elgato-stream-deck"
      "orcaslicer@nightly"
      "paintbrush"
      "via"
    ];
  };
}
