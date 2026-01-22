{
  config,
  currentYear,
  ...
}:

let
  navidrome = config.et42.server.navidrome;

  artistPlaylistsAttrs = import ./artist-playlists.nix;
  artistPlaylistsList = builtins.attrValues artistPlaylistsAttrs;

  decadePlaylists = navidrome.mkDecadePlaylists { inherit currentYear; };
  yearPlaylists = navidrome.mkYearPlaylists { inherit currentYear; };
  artistPlaylists = navidrome.mkArtistPlaylists artistPlaylistsList;

  allPlaylists = decadePlaylists ++ yearPlaylists ++ artistPlaylists;
  playlistsDir = navidrome.mkPlaylistsDir allPlaylists;
in
{
  inherit playlistsDir;
}
