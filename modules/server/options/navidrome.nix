{
  pkgs,
  lib,
  ...
}:

let
  mkPlaylistFile =
    {
      name,
      content,
      prefix ? "",
    }:
    let
      safeName = lib.toLower (lib.replaceStrings [ " " ":" "'" "\"" "/" ] [ "-" "" "" "" "-" ] name);
      filename = if prefix != "" then "${prefix}-${safeName}.nsp" else "${safeName}.nsp";
    in
    pkgs.writeTextFile {
      name = filename;
      text = builtins.toJSON content;
      destination = "/${filename}";
      executable = false;
    };

  mkDecadePlaylists =
    { currentYear }:
    let
      currentDecade = (currentYear / 10) * 10;
    in
    lib.flatten (
      builtins.genList (
        n:
        let
          decade = 1980 + (n * 10);
          endYear = decade + 9;
          decadeName = "${toString decade}s";
          playlistName = "Zeitgeist - Decade: ${decadeName}";

          playlistContent = {
            name = playlistName;
            comment = "Music from ${toString decade} to ${toString endYear}";
            all = [
              {
                inTheRange = {
                  year = [
                    decade
                    endYear
                  ];
                };
              }
            ];
            sort = "year";
            order = "asc";
          };
        in
        mkPlaylistFile {
          name = playlistName;
          content = playlistContent;
        }
      ) ((currentDecade - 1980) / 10 + 1)
    );

  mkYearPlaylists =
    {
      currentYear,
      yearCount ? 5,
    }:
    let
      startYear = currentYear - (yearCount - 1);
    in
    lib.flatten (
      builtins.genList (
        n:
        let
          year = startYear + n;
          yearStr = toString year;
          playlistName = "Zeitgeist - Year: ${yearStr}";

          playlistContent = {
            name = playlistName;
            comment = "Music released in ${yearStr}";
            all = [
              {
                is = {
                  year = year;
                };
              }
            ];
            sort = "title";
            order = "asc";
          };
        in
        mkPlaylistFile {
          name = playlistName;
          content = playlistContent;
        }
      ) yearCount
    );

  mkArtistPlaylists =
    playlistConfigs:
    map (
      playlistConfig:
      let
        artistConditions = map (artist: {
          is = {
            albumartist = artist;
          };
        }) playlistConfig.artists;

        bpmConditions =
          lib.optionals (playlistConfig ? bpmMin) [
            {
              gt = {
                bpm = playlistConfig.bpmMin - 1;
              };
            }
          ]
          ++ lib.optionals (playlistConfig ? bpmMax) [
            {
              lt = {
                bpm = playlistConfig.bpmMax + 1;
              };
            }
          ];

        playlistContent = {
          name = playlistConfig.name;
          comment = playlistConfig.comment;
          sort = playlistConfig.sort;
          order = playlistConfig.order;
          limit = playlistConfig.limit;
        }
        // (
          if bpmConditions != [ ] then
            {
              all = bpmConditions ++ [ { any = artistConditions; } ];
            }
          else
            { any = artistConditions; }
        );
      in
      mkPlaylistFile {
        name = playlistConfig.name;
        content = playlistContent;
      }
    ) playlistConfigs;

  mkPlaylistsDir =
    playlists:
    pkgs.runCommand "navidrome-playlists" { } ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (
        map (playlist: ''
          cp ${playlist}/* $out/
        '') playlists
      )}
    '';
in
{
  options.et42.server.navidrome = {
    mkPlaylistFile = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      description = "Function to generate a Navidrome playlist file";
      default = mkPlaylistFile;
    };

    mkDecadePlaylists = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      description = "Function to generate decade playlists";
      default = mkDecadePlaylists;
    };

    mkYearPlaylists = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      description = "Function to generate year playlists";
      default = mkYearPlaylists;
    };

    mkArtistPlaylists = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      description = "Function to generate artist playlists";
      default = mkArtistPlaylists;
    };

    mkPlaylistsDir = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      description = "Function to create a directory containing all playlist files";
      default = mkPlaylistsDir;
    };
  };
}
