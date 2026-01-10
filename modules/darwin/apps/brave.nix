{ ... }:

{
  homebrew.casks = [ "brave-browser" ];

  system.defaults.CustomUserPreferences."com.brave.Browser" = {
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

    # ui
    BookmarkBarEnabled = false;
    DefaultBrowserSettingEnabled = false;
    HideWebStoreIcon = true;
    ImportBookmarks = false;
    ImportHistory = false;
    ImportSavedPasswords = false;
    ShowHomeButton = false;
  };
}
