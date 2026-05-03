{ ... }:

{
  homebrew.casks = [ "chromium" ];

  system.defaults.CustomUserPreferences."org.chromium.Chromium" = {
    # extensions: declare the minimal set, force-installed and auto-updated
    ExtensionInstallForcelist = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx" # ublock origin lite
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa;https://clients2.google.com/service/update2/crx" # 1password
    ];

    # autofill
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    PasswordManagerEnabled = false;

    # privacy
    MetricsReportingEnabled = false;
    SafeBrowsingEnabled = false;
    SearchSuggestEnabled = false;
    SpellCheckServiceEnabled = false;
    TranslateEnabled = false;
    NetworkPredictionOptions = 2;
    UrlKeyedAnonymizedDataCollectionEnabled = false;

    # sync
    BrowserSignin = 0;
    SyncDisabled = true;

    # ui — suppress "make me default" prompts for browser and PDF
    AlwaysOpenPdfExternally = false;
    BookmarkBarEnabled = false;
    DefaultBrowserSettingEnabled = false;
    HideWebStoreIcon = true;
    ImportBookmarks = false;
    ImportHistory = false;
    ImportSavedPasswords = false;
    ShowHomeButton = false;
  };
}
