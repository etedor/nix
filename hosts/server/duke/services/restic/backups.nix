{
  specs = [
    {
      path = "/pool0/docker/volumes";
      excludes = [
        "media_jellyfin_config/_data/data/metadata"
        "media_radarr_config/_data/MediaCover"
        "media_sonarr_config/_data/MediaCover"
      ];
    }
    # podman volumes
    {
      path = "/pool0/podman/storage/volumes";
      excludes = [
        "jellyfin_config/_data/data/metadata"
        "radarr_config/_data/MediaCover"
        "sonarr_config/_data/MediaCover"
      ];
    }
    {
      path = "/pool0/users/eric";
      excludes = [ "**/.git" ];
    }
  ];
}
