{
  config,
  pkgs,
  ...
}:

let
  navidrome = config.et42.server.navidrome;

  artistPlaylistsAttrs = import ./artist-playlists.nix;
  artistPlaylistsList = builtins.attrValues artistPlaylistsAttrs;

  # dynamic year for decade/year playlists
  currentYear = builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommand "current-year" { } ''
        echo "$(date +%Y)" > $out
      ''
    )
  );

  decadePlaylists = navidrome.mkDecadePlaylists { inherit currentYear; };
  yearPlaylists = navidrome.mkYearPlaylists { inherit currentYear; };
  artistPlaylists = navidrome.mkArtistPlaylists artistPlaylistsList;

  allPlaylists = decadePlaylists ++ yearPlaylists ++ artistPlaylists;
  playlistsDir = navidrome.mkPlaylistsDir allPlaylists;
in
{
  inherit playlistsDir;
}
