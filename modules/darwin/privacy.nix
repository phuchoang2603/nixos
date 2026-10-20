{ lib, ... }:

let
  payload =
    domain: uuid: preferences:
    preferences
    // {
      PayloadType = domain;
      PayloadIdentifier = "org.nixos.felix.privacy.${domain}";
      PayloadUUID = uuid;
      PayloadVersion = 1;
      PayloadEnabled = true;
    };
in
{
  environment.etc."privacy.mobileconfig".text = lib.generators.toPlist { escape = true; } {
    PayloadType = "Configuration";
    PayloadIdentifier = "org.nixos.felix.privacy";
    PayloadUUID = "41680D32-C24E-5667-9FBA-92F9F0E89B16";
    PayloadVersion = 1;
    PayloadDisplayName = "macOS Privacy";
    PayloadDescription = "Disable analytics sharing, personalized ads, online search suggestions, Siri, Apple Intelligence features, Apple Music, and Book Store.";
    PayloadScope = "System";
    PayloadRemovalDisallowed = false;
    PayloadContent = [
      (payload "com.apple.applicationaccess" "4B1534EE-946F-50AD-86D0-94D9D36BFF42" {
        allowDiagnosticSubmission = false;
        allowApplePersonalizedAdvertising = false;
        allowSpotlightInternetResults = false;
        allowMusicService = false;
        allowBookstore = false;
        allowAssistant = false;
        allowExternalIntelligenceIntegrations = false;
        allowWritingTools = false;
        allowGenmoji = false;
        allowImagePlayground = false;
        allowMailSmartReplies = false;
        allowMailSummary = false;
        allowNotesTranscriptionSummary = false;
        allowSafariSummary = false;
      })
      (payload "com.apple.SubmitDiagInfo" "4A321697-9F77-5848-B00E-29C96CD5AD74" {
        AutoSubmit = false;
      })
      (payload "com.apple.assistant.support" "B4BAEB68-B875-5480-893D-AFA64EDAB17B" {
        "Siri Data Sharing Opt-In Status" = 2;
        "Search Queries Data Sharing Status" = 2;
      })
      (payload "com.apple.lookup.shared" "80D448EA-9DAA-58A1-8F3C-FA5FCC95B1EE" {
        LookupSuggestionsDisabled = true;
      })
      (payload "com.apple.Safari" "98C5D633-E6DB-53AA-A01E-9735C2E16D4E" {
        SuppressSearchSuggestions = true;
        UniversalSearchEnabled = false;
      })
    ];
  };
}
