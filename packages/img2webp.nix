{ writeShellApplication, libwebp }:
let
  cwebp = "${libwebp}/bin/cwebp";
in
writeShellApplication {
  name = "img2webp";
  runtimeInputs = [ libwebp ];
  meta.description = ''
    Convert images to WebP format.
  '';
  text = ''
    for f in "$@"; do
        name=$(${../scripts/file_name.sh} "$f");
        ${cwebp} -q 70 "$f" -o "./$name.webp";
    done
  '';
}
