{ ... }:

{
  system.defaults.NSGlobalDomain = {
    # disable autocorrect
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;

    # disable "natural" scroll direction
    "com.apple.swipescrolldirection" = false;
  };
}
