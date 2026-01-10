{
  config,
  globals,
  specialArgs,
  ...
}:

{
  age.secrets.icecast = {
    file = "${specialArgs.secretsHost}/icecast.age";
    mode = "0400";
  };

  et42.server.radio = {
    enable = true;
    port = 8001;
    credentialsFile = config.age.secrets.icecast.path;
    adminContact = "admin@${globals.zone}";
    adminIPs = [ "10.0.8.0/24" ]; # TODO

    stations = [
      {
        name = "kexp";
        url = "https://kexp.streamguys1.com/kexp160.aac";
        fullName = "KEXP 90.3 FM";
        description = "Where the Music Matters";
        genre = "Eclectic";
      }
      {
        name = "kuow";
        url = "https://playerservices.streamtheworld.com/api/livestream-redirect/KUOWFM_AAC.aac";
        fullName = "KUOW 94.9 FM";
        description = "Seattle's NPR Station";
        genre = "Public Radio";
      }
      {
        name = "indiepop";
        url = "http://ice3.somafm.com/indiepop-128-aac";
        fullName = "Indie Pop Rocks!";
        description = "New and classic favorite indie pop tracks.";
        genre = "Indie";
      }
      {
        name = "nightride";
        url = "https://stream.nightride.fm/nightride.m4a";
        fullName = "Nightride FM";
        description = "The Home of Synthwave Radio";
        genre = "Synthwave";
      }
      {
        name = "poptron";
        url = "http://ice3.somafm.com/poptron-128-aac";
        fullName = "PopTron";
        description = "Electropop and indie dance rock with sparkle and pop.";
        genre = "Indie";
      }
    ];
  };
}
