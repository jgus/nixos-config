{ lib
, stdenv
, fetchurl
, nodejs
, python3
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "cline";
  version = "1.0.8";

  src = fetchurl {
    url = "https://registry.npmjs.org/cline/-/cline-${version}.tgz";
    hash = "sha256-30hGGzR0X5p4BlzYVyfqnrcUnUjGjOf0ahKFOnww5vo=";
  };

  nativeBuildInputs = [ nodejs python3 makeWrapper ];

  buildPhase = ''
    runHook preBuild
    
    # Set up environment for node-gyp
    export HOME=$TMPDIR
    export npm_config_nodedir=${nodejs}
    
    # Install directly from the tarball
    npm install --global --prefix=$out $src
    
    runHook postBuild
  '';

  dontInstall = true;

  postFixup = ''
    for bin in $out/bin/*; do
      if [ -f "$bin" ]; then
        wrapProgram $bin --prefix PATH : ${lib.makeBinPath [ nodejs ]}
      fi
    done
  '';

  meta = with lib; {
    description = "Cline CLI";
    homepage = "https://cline.bot";
    license = licenses.asl20;
    mainProgram = "cline";
  };
}
