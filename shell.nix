with (import <nixpkgs> { });
mkShell {
  buildInputs = [ libsoundio jack2 pkg-config zig ];
  LD_LIBRARY_PATH = "${pkgs.libsoundio}/lib";
}
