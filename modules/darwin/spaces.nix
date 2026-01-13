{ ... }:

{
  # enable Mission Control desktop switching shortcuts
  # ctrl+1 through ctrl+9, ctrl+0 for desktop 10
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # format: parameters = (unicode, keycode, modifiers)
        # modifiers: 262144 = ctrl
        "118" = {
          enabled = true;
          value = {
            parameters = [ 65535 18 262144 ];
            type = "standard";
          };
        };
        "119" = {
          enabled = true;
          value = {
            parameters = [ 65535 19 262144 ];
            type = "standard";
          };
        };
        "120" = {
          enabled = true;
          value = {
            parameters = [ 65535 20 262144 ];
            type = "standard";
          };
        };
        "121" = {
          enabled = true;
          value = {
            parameters = [ 65535 21 262144 ];
            type = "standard";
          };
        };
        "122" = {
          enabled = true;
          value = {
            parameters = [ 65535 23 262144 ];
            type = "standard";
          };
        };
        "123" = {
          enabled = true;
          value = {
            parameters = [ 65535 22 262144 ];
            type = "standard";
          };
        };
        "124" = {
          enabled = true;
          value = {
            parameters = [ 65535 26 262144 ];
            type = "standard";
          };
        };
        "125" = {
          enabled = true;
          value = {
            parameters = [ 65535 28 262144 ];
            type = "standard";
          };
        };
        "126" = {
          enabled = true;
          value = {
            parameters = [ 65535 25 262144 ];
            type = "standard";
          };
        };
        "127" = {
          enabled = true;
          value = {
            parameters = [ 65535 29 262144 ];
            type = "standard";
          };
        };
      };
    };
  };

}
