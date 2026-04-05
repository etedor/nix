{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
  beetsWithPlugins = pkgs.python3.pkgs.toPythonApplication (pkgs.python3.pkgs.beets.override {
    pluginOverrides = {
      autobpm.enable = true;
      chroma.enable = true;
      embedart.enable = true;
      fetchart.enable = true;
      lastgenre.enable = true;
      replaygain.enable = true;
    };
  });
in
{
  environment.systemPackages = with pkgs; [
    flac
    lame
  ];

  home-manager.users.${user0.name} = {
    programs.fish.functions.beet-art = {
      description = "Clear, embed, and extract album art";
      body = ''
        set -l url $argv[1]
        set -l query $argv[2..-1]

        set -l album_path (beet list -a -f '$path' $query)

        if test -z "$album_path"
            echo "Album not found: $query"
            return 1
        end

        beet clearart $query || return 1
        beet embedart -u "$url" $query || return 1
        rm -f "$album_path"/cover.{jpg,jpeg,png,webp} 2>/dev/null
        beet extractart -n cover $query
      '';
    };

    programs.beets = {
      enable = true;
      package = beetsWithPlugins;

      settings = {
        directory = "/pool0/media/library/music";
        library = "/home/${user0.name}/.config/beets/musiclibrary.blb";
        threaded = true;

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

        album_fields = {
          artist_path = "albumartist_sort or albumartist or 'Unknown Artist'";
          yr = "original_year if original_year else year";
        };

        paths = {
          default = "$artist_path/$yr. $album%aunique{}/%if{$multidisc,Disc $disc/}$track. $title";
          singleton = "Singles/$artist - $title";
          comp = "Compilations/$yr. $album%aunique{}/$disc/$track. $title";
          albumtype_soundtrack = "Soundtracks/$yr. $album/$track. $title";
        };

        import = {
          write = true;
          copy = false;
          move = true;
          resume = "ask";
          incremental = false;
          quiet_fallback = "skip";
          duplicate_action = "remove";
          timid = false;
          log = "/home/${user0.name}/.config/beets/beet.log";
        };

        match.strong_rec_thresh = 0.85;

        autobpm.auto = true;

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
          whitelist = ./genres.txt;
          prefer_specific = true;
          force = true;
        };

        replaygain.auto = false;
        scrub.auto = true;

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
