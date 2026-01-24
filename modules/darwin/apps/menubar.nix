{
  ...
}:
{
  system.defaults.NSGlobalDomain._HIHideMenuBar = false;

  system.defaults.CustomUserPreferences."com.jordanbaird.Ice" = {
    AutoRehide = true;
    CanToggleAlwaysHiddenSection = true;
    CustomIceIconIsTemplate = false;
    EnableAlwaysHiddenSection = true;
    EnableSecondaryContextMenu = true;
    HideApplicationMenus = true;
    IceBarLocation = 0;
    ItemSpacingOffset = 0;
    RehideInterval = 15;
    RehideStrategy = 0;
    SectionDividerStyle = 0;
    ShowAllSectionsOnUserDrag = true;
    ShowIceIcon = true;
    ShowOnClick = true;
    ShowOnHover = false;
    ShowOnHoverDelay = 0.2;
    ShowOnScroll = true;
    TempShowInterval = 15;
    UseIceBar = false;
  };

  homebrew.casks = [
    "jordanbaird-ice@beta"
    "swiftbar"
  ];
}
