{
  # for distributed builds
  builders = {
    machina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMedB0Yoxfex9pL3kR/kXTw4BstybyhwLCHOjtcQRcYK";
  };

  # for agenix and authorized_keys
  users.user0 = {
    carbon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPyQPzZjubGGsva59VOUWMdPWIkr74JaxlgVnKN09Xwe";
    duke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOu8kbwE6phergM4akwVvxsiTyq/aJlWYOHYc7I4h8nA";
    garage = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8qSz/2YMNtP72GK+z6duhXJMc2mlTKRVtpMt8uwUDV";
    machina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExdNBsYVsnRrfYNggm9vOYAkeh+qpy02tNLP5zXugC5";
    rt-ggz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyVg+2cpXg8H9iUIfzTFrKZ7/MgJoAGVjc4LHzDuIlr";
    rt-sea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFNrJr2ZKEbNljmxxN4ib8Lf1vL4KJSSoWmbrssZOk";
  };

  # for agenix and knownHosts
  hosts = {
    duke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAF4Hqb6luc7cU27HlOYM73wiSTw44lyik5iuZvBlnjg";
    garage = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdGrhtVsXuWki9yBCk+X3N7dK5TUKjH4v5Cqg9eHqP0";
    machina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ8JWSXdfj6L1cX82Ha8OuSn8u3ZozvuSWqOIeizItvO";
    rt-ggz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGI4dXS3GneSRGa0gB773D9VsuBG/yPBdHHQkkUwURmK";
    rt-sea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqcrgjHPx1SbllfVSCLcj/g29HAW/qcv6i6ZYoNs99h";
  };
}
