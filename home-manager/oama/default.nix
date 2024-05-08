{ ... }:

{
  programs.oama = {
    enable = true;
    settings = {
      encryption.tag = "KEYRING";
      services.google = {
        # Cribbed from Thunderbird
        # https://hg-edge.mozilla.org/comm-central/file/tip/mailnews/base/src/OAuth2Providers.sys.mjs
        client_id = "406964657835-aq8lmia8j95dhl1a2bvharmfk3t1hgqj.apps.googleusercontent.com";
        client_secret = "kSmqreRr0qwBWJgbf5Y-PjSU";
        auth_scope = "https://mail.google.com/ https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/carddav";
      };
    };
  };
}
