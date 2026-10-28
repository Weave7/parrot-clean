// Override Kali's enterprise-policy homepage (file:///usr/share/kali-defaults/web/homepage.html)
// with Google. The policy is unlocked, so a user pref takes precedence.
user_pref("browser.startup.homepage", "https://www.google.com");
user_pref("browser.startup.page", 1);

// Required for userChrome.css / userContent.css (chrome/ dir) to be loaded.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
