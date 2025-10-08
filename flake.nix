{
  description = "ZPLinux Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
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

      packages.x86_64-linux = {
        zplinuxFloppyA = floppyA;
      };

      apps.x86_64-linux = {
        default =
          let
            script = pkgs.writeShellScriptBin "run-in-qemu" ''
              qemu-system-i386 \
                -cpu 486 -m 16M \
                -drive file=${floppyA}/zplinux-floppy-a.img,if=floppy,format=raw,readonly=on
            '';
          in
          {
            type = "app";
            program = "${script}/bin/run-in-qemu";
          };
        checkFloppyADiskSpace =
          let
            script = pkgs.writeShellScriptBin "check-floppy-a-disk-space" ''
              cat ${floppyA}/disk-usage.txt
            '';
          in
          {
            type = "app";
            program = "${script}/bin/check-floppy-a-disk-space";
          };

      };

      devShells.x86_64-linux = {

        kernel =
          (pkgs.buildFHSEnv {
            name = "kernel-devshell";
            targetPkgs =
              pkgs_:
              (with pkgs_; [
                pkg-config
                ncurses
                stdenv.cc
                stdenv.cc.bintools
                flex
                bison
                bc
                pkgsi486.stdenv.cc.bintools.bintools
                pkgsi486.stdenv.cc.cc
              ]);
            runScript = pkgs.writeScript "init.sh" ''
              export CROSS_COMPILE=i486-unknown-linux-musl-
              export ARCH=x86
              export PKG_CONFIG_PATH=${pkgs.ncurses.dev}/lib/pkgconfig

              cd $TMPDIR

              tar xf ${kernel.src}
              cd linux-${kernel.version}

              cp ${./packages/kernel/kernel-config} .config

              exec zsh
            '';
          }).env;

      };

    };
}
