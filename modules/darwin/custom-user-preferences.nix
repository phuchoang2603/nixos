{ ... }:

{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "163" = {
          # Set 'Option + N' for Show Notification Center
          enabled = true;
          value = {
            parameters = [
              110
              45
              524288
            ];
            type = "standard";
          };
        };
        "36".enabled = false; # Show Desktop (F11)
        "64".enabled = false; # Spotlight Search (Cmd + Space)
        "60".enabled = false; # Disable '^ + Space' for selecting the previous input source
        "65".enabled = false; # Finder Search (Cmd + Alt + Space)
        "184".enabled = false; # Default Screenshot
      };
    };
    "com.apple.spotlight" = {
      "SiriSuggestionsEnabled" = false;
      "orderedItems" = {
        "SiriSuggestions" = 0;
      };
    };
    "com.apple.suggestions" = {
      "SiriSuggestionsEnabled" = false;
    };
  };
}
