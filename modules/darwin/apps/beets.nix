{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  environment.systemPackages = with pkgs; [
    chromaprint
    ffmpeg
    flac
    lame
  ];

  home-manager.users.${user0.name} = {
    programs.fish.functions.beet-art = {
      description = "Clear, embed, and extract album art";
      body = ''
        set -l url $argv[1]
        set -l query $argv[2..-1]

        # get album path
        set -l album_path (beet list -a -f '$path' $query)

        if test -z "$album_path"
            echo "Album not found: $query"
            return 1
        end

        # clear embedded art
        beet clearart $query || return 1

        # embed new art
        beet embedart -u "$url" $query || return 1

        # remove existing cover files
        rm -f "$album_path"/cover.{jpg,jpeg,png,webp} 2>/dev/null

        # extract new art
        beet extractart -n cover $query
      '';
    };

    programs.beets = {
      enable = true;

      settings = {
        # core settings
        directory = "/Volumes/duke/media/library/music";
        library = "/Volumes/duke/users/${user0.name}/.config/beets/musiclibrary.blb";
        threaded = true;

        # plugins configuration
        plugins = [
          "autobpm"
          "chroma"
          "convert"
          "edit"
          "embedart"
          "fetchart"
          "inline"
          "lastgenre"
          "musicbrainz"
          "replaygain"
          "scrub"
        ];

        item_fields = {
          multidisc = "1 if disctotal > 1 else 0";
        };

        # path patterns
        paths = {
          default = "$albumartist_sort/$original_year. $album%aunique{}/%if{$multidisc,Disc $disc/}$track. $title";
          singleton = "Singles/$artist - $title";
          comp = "Compilations/$original_year. $album%aunique{}/$disc/$track. $title";
          albumtype_soundtrack = "Soundtracks/$original_year. $album/$track. $title";
        };

        # import settings
        import = {
          write = true;
          copy = false;
          move = true;
          resume = "ask";
          incremental = false;
          quiet_fallback = "skip";
          timid = false;
          log = "/Users/${user0.name}/.config/beets/beet.log";
        };

        # plugin-specific settings
        autobpm = {
          auto = true;
        };

        embedart = {
          auto = true;
          sources = "albumart amazon itunes";
          enforce_ratio = true;
          quality = 100;
        };

        fetchart = {
          auto = true;
          sources = [
            "itunes"
            "coverart"
            "amazon"
            "albumart"
            "filesystem"
          ];
        };

        lastgenre = {
          auto = true;
          source = "artist";
          canonical = true;
          whitelist = ./beets/genres.txt;
          prefer_specific = true;
          force = true;
        };

        replaygain = {
          auto = false;
        };

        scrub = {
          auto = true;
        };

        # character replacement rules
        replace = {
          "^\\." = "_";
          "[\\x00-\\x1f]" = "_";
          "[<>:\"\\?\\*\\|]" = "_";
          "[\\xE8-\\xEB]" = "e";
          "[\\xEC-\\xEF]" = "i";
          "[\\xE2-\\xE6]" = "a";
          "[\\xF2-\\xF6]" = "o";
          "[\\xF8]" = "o";
          "\\.$" = "_";
          "\\s+$" = "";
        };

        # additional settings
        art_filename = "cover";
        clutter = [
          ".DS_Store"
          "Thumbs.DB"
          "cover.jpg"
          "cover.png"
        ];
        original_date = true;
        per_disc_numbering = true;
      };
    };
  };
}
