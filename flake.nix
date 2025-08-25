{
  description = "ZPLinux Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsi486 = import nixpkgs {
          localSystem = {
            system = system;
          };
          crossSystem = {
            config = "i486-unknown-linux-musl";
            gcc = {
              arch = "i486";
              tune = "i486";
            };
          };
          config = {
            allowUnsupportedSystem = true;
          };
        };
        kernel = pkgs.callPackage ./packages/kernel { inherit pkgsi486; };
        busybox = import ./packages/busybox { inherit pkgs pkgsi486; };
        floppyA = import ./packages/floppies/A {
          inherit pkgs pkgsi486;
          kerneli486 = kernel;
          busyboxi486Static = busybox;
        };
      in
      {

        apps = {
          default =
            let
              script = pkgs.writeShellScriptBin "run-in-qemu" ''
                exec qemu-system-i386 \
                  -cpu 486 -m 16M \
                  -drive file=${floppyA}/zplinux-floppy-a.img,if=floppy,format=raw,readonly=on
              '';
            in
            {
              type = "app";
              program = "${script}/bin/run-in-qemu";
            };
        };
      }
    );
}
