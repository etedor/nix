{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
  addons = pkgs.nur.repos.rycee.firefox-addons;

  uiCustomization = builtins.toJSON {
    placements = {
      nav-bar = [
        "sidebar-button"
        "back-button"
        "forward-button"
        "stop-reload-button"
        "urlbar-container"
        "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action" # 1password
        "downloads-button"
        "unified-extensions-button"
        "vertical-spacer"
      ];
      unified-extensions-area = [
        "addon_darkreader_org-browser-action"
        "search_kagi_com-browser-action"
        "ublock0_raymondhill_net-browser-action"
      ];

      PersonalToolbar = [ "personal-bookmarks" ];
      TabsToolbar = [ ];
      vertical-tabs = [ "tabbrowser-tabs" ];
      widget-overflow-fixed-list = [ ];
    };
    currentVersion = 23; # prevents firefox from "migrating" toolbar config
  };
in
{
  home-manager.users.${user0.name} = {
    programs.firefox = {
      enable = true;

      policies = {
        # autofill
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableFormHistory = true;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;

        # homepage
        FirefoxHome = {
          Pocket = false;
          Search = false;
          Shortcuts = false;
          Snippets = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
          Weather = false;
        };
        Homepage = {
          StartPage = "none";
          URL = "about:blank";
        };
        NewTabPage = false;
        NoDefaultBookmarks = true;

        # privacy
        DisableFirefoxAccounts = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableProfileImport = true;
        DisableTelemetry = true;
        EnableTrackingProtection = {
          Cryptomining = true;
          Fingerprinting = true;
          Value = true;
        };

        # search
        FirefoxSuggest = {
          ImproveSuggest = false;
          SponsoredSuggestions = false;
          WebSuggestions = false;
        };
        SearchEngines.Remove = [
          "Amazon.com"
          "Bing"
          # "DuckDuckGo"
          "eBay"
          "Google"
          "Wikipedia (en)"
        ];

        # ui
        DontCheckDefaultBrowser = false;
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
        };

        Preferences = {
          "browser.uiCustomization.state" = {
            Value = uiCustomization;
            Status = "locked";
          };
          "sidebar.main.tools" = {
            Value = "";
            Status = "locked";
          };
          "sidebar.position_start" = {
            Value = true;
            Status = "locked";
          };
        };
      };

      profiles.default = {
        isDefault = true;
        path = "default";

        extensions.packages = with addons; [
          darkreader
          kagi-search
          # onepassword-password-manager # install via 1password app
          ublock-origin
        ];

        settings = {
          # ai
          "browser.ml.chat.enabled" = false;
          "browser.ml.chat.sidebar" = false;
          "browser.ml.chat.shortcuts" = false;
          "browser.ml.enable" = false;
          "browser.tabs.groups.smart.enabled" = false;

          # media
          "media.hardwaremediakeys.enabled" = false;

          # network
          "media.peerconnection.enabled" = false;
          "network.dns.disablePrefetch" = true;
          "network.predictor.enabled" = false;
          "network.prefetch-next" = false;
          "network.trr.mode" = 5;

          # search
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.topsites" = false;

          # ui
          "browser.download.autohideButton" = false;
          "sidebar.main.tools" = "";
          "sidebar.position_start" = true;
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
        };
      };
    };
  };
}
