// Load chrome/userChrome.css (translucent toolbar + sidebar).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Let the toplevel window have an alpha channel so translucent chrome shows the desktop.
user_pref("widget.transparent-windows", true);
// Don't dim the URL path after the domain in the address bar.
user_pref("browser.urlbar.formatting.enabled", false);
// Allow tab content to be transparent (only the start page uses it; see userChrome/userContent.css).
user_pref("browser.tabs.allow_transparent_browser", true);
