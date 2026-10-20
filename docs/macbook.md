# MacBook

Apple Silicon, using account `felix` and an existing copy of this repository.

## Install

Run each installer only if it is needed. Finish the command-line tools dialog
before continuing.

```bash
xcode-select --install
```

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Build and apply:

```bash
cd /path/to/nixos
sudo nix --extra-experimental-features 'nix-command flakes' \
  run --inputs-from . nix-darwin#darwin-rebuild -- switch --flake .#macbook
```

## Rebuild

```bash
cd /path/to/nixos
sudo darwin-rebuild switch --flake .#macbook
```

## Vicinae

Vicinae is installed from nixpkgs into `~/Applications/Home Manager Apps` and
started by a Home Manager LaunchAgent.
Use **Option + Space** to open it, **Option + C** for the calculator,
**Option + V** for clipboard history, **Option + F** for file search,
**Option + W** to switch windows, and **Option + S** for System Monitor.

In **System Settings → Privacy & Security**, allow Vicinae **Accessibility** for
snippet expansion and pasting, and **Full Disk Access** for searching protected
folders. Restart Vicinae after granting access.

**Option + O** selects a screen region, recognizes English text locally with Tesseract,
and copies it to the clipboard. Allow screen recording when macOS prompts.

The configuration disables Spotlight's keyboard shortcuts and Siri suggestions,
not its indexing. Vicinae uses the Spotlight index for file search. Check it with:

```bash
mdutil -s /
```

If indexing is disabled, enable it with `sudo mdutil -i on /`. In
**System Settings → Spotlight → Search Privacy**, make sure your disk and desired
search folders are not excluded. On older macOS versions, this is under
**Siri & Spotlight → Spotlight Privacy**.

## Privacy settings

Nix generates `/etc/privacy.mobileconfig` to disable Mac Analytics, personalized ads,
Improve Siri and Dictation, Improve Search, Spotlight internet results, Look Up
suggestions, Safari search suggestions, Apple Music, and the Book Store.

The profile also disables Siri, external AI integrations such as ChatGPT, Writing
Tools, Genmoji, Image Playground, Mail smart replies, and summaries in Mail, Notes,
and Safari. These are individual feature restrictions, not a global Apple
Intelligence switch. Apple deprecates these restriction keys starting in macOS 26.4
in favor of declarative device management.

After rebuilding, run `open /etc/privacy.mobileconfig` and approve installation in
**System Settings → General → Device Management**. macOS requires this manual step;
rebuilding alone does not install or update the profile. Reinstall it after changing
the profile settings in Nix.

## Edit server secrets

```bash
cd /path/to/nixos/secrets/server
nix run --inputs-from ../.. agenix -- -e traefik.env.age -i ~/.ssh/id_ed25519
```

Use the desired encrypted filename, then copy the updated file to the server
checkout and rebuild it. Keep the MacBook private key backed up in Bitwarden;
it can stay on the MacBook.
