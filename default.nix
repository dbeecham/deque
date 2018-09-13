with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "libdeque";
  src = ./.;
  installFlags = [ "DESTDIR=$(out)" "PREFIX=/" ];
  doCheck = true;
  nativeBuildInputs = [ python37Packages.gcovr ];
  phases = [ "unpackPhase" "testPhase" "buildPhase" "checkPhase" "installPhase" "fixupPhase" ];
  buildPhase = ''
    make EXTRA_CFLAGS="-O1 -fsanitize=leak,undefined -fstack-protector-strong -Wduplicated-cond -Wduplicated-branches -Wvla -Werror -pedantic" EXTRA_LDFLAGS="-fsanitize=leak,undefined -fstack-protector-strong"
  '';
  testPhase = ''
    mkdir $out
    make -B test
    make clean distclean
  '';
  checkPhase = ''
    echo yes
  '';
}
