# multipass-flake

> **This repo is now archived, as its contents are included in nixpkgs/nixos itself. See this
> [PR](https://github.com/NixOS/nixpkgs/pull/214193) for more details.**

This is a Nix Flake for Canonical's [Multipass](https://multipass.run). You can use this flake
to build/install the `multipass` package, or you can use it with your NixOS system to enable
multipass as a virtualisation provider.

This flake is not supported or endorsed by Canonical in any way, it is just a personal project.

## Use this flake on NixOS

1. Add the flake as an input to your system config flake:

```
...
inputs = {
    multipass = {
      url = "github:jnsgruk/multipass-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
}
...
```

2. Make sure the module is added to your system configuration:

```
...
nixosConfigurations = {
    thor = nixpkgs.lib.nixosSystem {
        ...
        modules = [
            multipass.nixosModule."x86_64-linux"
            ...
        ];
    };
};
...
```

3. Enable multipass in your NixOS system configuration:

```
virtualisation.multipass.enable = true;
```

4. Reload your nix configuration, you may need to run `systemctl start multipass`

## Caveats

Not many. I don't think this will work out of the box on non-amd64 machines without tweaking
the patches/paths for the OVMF/bios files for QEMU. I don't have access to such machines and have
not tested it.
