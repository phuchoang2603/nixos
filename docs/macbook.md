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

## Edit server secrets

```bash
cd /path/to/nixos/secrets/server
nix run --inputs-from ../.. agenix -- -e traefik.env.age -i ~/.ssh/id_ed25519
```

Use the desired encrypted filename, then copy the updated file to the server
checkout and rebuild it. Keep the MacBook private key backed up in Bitwarden;
it can stay on the MacBook.
