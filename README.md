# Zen Browser

This is a flake for the Zen browser.

Just add it to your NixOS `flake.nix` or home-manager:

```nix
inputs = {
  zen-browser.url = "github:bodenlosus/zen-browser-flake";
  ...
}
```

## Packages

as of Zen Browser `1.0.2-b.4` the `generic` and `specific` branch don't exist.

The flake provides packages for both `x86_64-linux` and `aarch64-linux`.

To install add one of the following lines:

in `configuration.nix`
```nix
environment.systemPackages = {
  #...
  inputs.zen-browser.packages."${system}"
}
```
or 
```nix
home.packages = {
  #...
  inputs.zen-browser.packages."${system}"
}
```

Depending on which version you want

```shell
$ sudo nixos-rebuild switch
$ zen
```

## 1Password

Zen has to be manually added to the list of browsers that 1Password will communicate with. See [this wiki article](https://nixos.wiki/wiki/1Password) for more information. To enable 1Password integration, you need to add the line `.zen-wrapped` to the file `/etc/1password/custom_allowed_browsers`.

# Credits
Original flake was written by MarceColl
