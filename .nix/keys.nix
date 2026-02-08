{
  wireguard = {
    rt-ggz = {
      wg0 = "q0iv3xaqimX9Y5YmLH0/iGq2uHEzzVdV8V0H8RC9vH4=";
      wg1 = "Ofl41GVWAVi60NsIPMVg8o0RYJDfOFbYuL+WfSUJAjM=";
    };
    rt-ggz2 = {
      wg0 = "oFvV6HXFAdemlOrTJpSLCInJDhJlCQiclAxd0qZHSwA=";
      wg1 = "477ARIZxm7mS5ksYtkSN+KVCHoBCZojLwhQceYMnkB8=";
    };
    rt-sea = {
      wg0 = "hewTOjDLRD5ML+d3bsHb7RFDsRt9bNFxhoMfOrd0F0A=";
      wg1 = "0+B4E8kCsCxZgF1mqHsj9O0cGu8ylC5/EtNzi1yL0yU=";
      wg2 = "fGL4pI3schfcqtkGVyn2LqyU6mRRaASoRKQ84fHc7ms=";
      wg10 = "niKrQNH3U7QGSsqvxL+rK5UAZTHEADkYWAk/GHy1YHc=";
      wg11 = "UTFPct/zmzcBdzP2whojDvhYyZ2Mu8vJQ02DedpqvF8=";
    };
    rt-sea2 = {
      wg0 = "L8tbWcMTj6xNCjTK7756v7BZrbo1hJsaR5xO+xDtFwo=";
      wg1 = "QH3TWgd527SWZ+JWonjJ7ZbYmc+/uSmg9vYaOJ5LDms=";
      wg2 = "egAg/SAMlZYUsGycbLACjmliQhXiktS5reOQKa4GEGM=";
    };
    pine = {
      wg0 = "xBNt1u2PhjNwRdZbGqPUYg89ZgXtK96CdzdgGHBkzgE=";
    };
    jade = {
      wg0 = "dYW3muFz+5SalLTS+WyVPLZIqFAcGqf3LQX22GGXIlA=";
    };
    carbon = {
      wg0 = "BFj2h8WFEB4k6iwEUlqTIbDCACpIeib+zBZP0st9N20=";
    };
    rt-travel = {
      wg0 = "K3x4FcfB16JwPeO3UUML7PSLYtwAd8Ostp+QJxgl63k=";
    };
  };

  # for distributed builds
  builders = {
    machina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMedB0Yoxfex9pL3kR/kXTw4BstybyhwLCHOjtcQRcYK";
  };

  # service account
  users.claude-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVGN1ZBhoXks8heaUE3n2TainlBcUxmUsQTAFjKanfR claude@nix";
  users.claude-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDqxQ93+eqNIqA5XkbpXOcaiQ+/jjHa+B7VTjqFuALMNjhisoXOcvmQsPzmhj0hWMv2Vg3zWKScD+AM//Ly7ocPpQUlugLDtioN7UefJhub0APUtaGJh2jjk2cGnW57+fvTB+Rv19GZGUxApj76xTFPTA26kalNW4u/gZ+cwwo+jTUA6l13CZGwp6iYRBcJKpvBMhY7ua/rUjGENVKHsGCQCn/DrqUpzy/VtOqMveVnN+sbJd2ANCSpEcz26JhmglTWH30HfwUa4XNwA5k3T+yrVzvxZ/jIXGP1iipM+kiUhFD/cPyrmD61LTD8ByGTnlKUsMX6pC6jYPCXP2GBDhrKpr08LzrRP3MTWoFhmLfJb+v4TttUPIwiHVfplnm9fkBIBVfXE1WMORPq7Oq5gSk6OuVjVUVTonkgcv2zynWLCXGrk/o7mf4iNrzL0nNnM7cx2ZvtAXYLVw/bMCSy/bt7gYe+bkY4lKr5d2GmcqPnU1mgPHUUSk4OUCwL7XWj1R3ZbREuf2CkwgGGbJuJ6+/Po7EarRTxJ9bXF1zmP4V65z+3EVMSvua7rWfUnQm7DTl40yGmpOIpoUxkoXUKX95X05XWIFaiqI8rzk6uhW6FXUN7fCMeuaEmu6AHXNf3jhbeFkUMXg6KG4GaZ/T4nLcVv7/TJfcKXnO9NobDQWLXvw== claude@nix";

  # shared user keys
  users.user0-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATSrykGxZwImWE+NJ1t070esHjvL6sEu0/srxUofsMH eric@tedor.org";
  users.user0-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbqzOAGOzAZTA64ti/VtoZisNBkCL75GdgQ/RODU53JPhiw4AlgJ7IKKQxcz8N0KiPxJV6cbCvlu1pdrrF/ixICXJHfXBNx3pWjoxhAT0wp7aVfZGYDyWfhRY1Cn1ntRpizrUlFKbyOASJ8/3NAJFJoIh9FQx0gweR3P8T8mkg8uBcMIHlqzZ83HclfqD4yDNX7CNAfDsAUADwVOOn1t6qTkC0O9Mq3qWCkl5lhRuBhUYal8jLVWiXmPBdWtD+ByUGYxH8duJzREJJ2HEyoRSeHI6C5tiFDI9KpK7JeKrA1138XsgCa4n7ozov2aENcounr/e3SOLx9aHWJUclk5P09ryiYAg4rvkX9tlggFrWeJUD+LS/HNtN+G+E9U++ay3QMzshNUF/U4/QRvm+GC82AU4l7Wmh7P3IaCisJJAtWpcw+vYfGWxRNROG07In2wAQnVK8k3IKwzGfW3tb40c/kg2E5LT5oWhVnPFVTbSEjF7B+lOkVCHi/vX4pV8GCFx4XXqvkA+nM0lpaGHLXd74JbG5EtrhP7dxzvqgQIKsnz3ZrObTSk+CCwCX6/tsK6E2kgk6ThHNCxtf+EMC8Kig2JZhd4pAJW4y9mGjxKi6l0c4xQ74k05Swn0W5H5umrOsbgqyKsHi1MRZb7Ea22Ds34eYaZKmSz1QOkndjUHbDw== eric@tedor.org";

  # per-host user keys (agenix recipients)
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
    # darwin
    carbon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPyQPzZjubGGsva59VOUWMdPWIkr74JaxlgVnKN09Xwe";
    garage = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdGrhtVsXuWki9yBCk+X3N7dK5TUKjH4v5Cqg9eHqP0";
    machina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ8JWSXdfj6L1cX82Ha8OuSn8u3ZozvuSWqOIeizItvO";

    # router
    rt-ggz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGI4dXS3GneSRGa0gB773D9VsuBG/yPBdHHQkkUwURmK";
    rt-sea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqcrgjHPx1SbllfVSCLcj/g29HAW/qcv6i6ZYoNs99h";
    rt-sea2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC5Ti+DbFuHLyT/ilpwmuO0zDZShiuRvilluWyFynic/";

    # server
    duke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAF4Hqb6luc7cU27HlOYM73wiSTw44lyik5iuZvBlnjg";
  };
}
