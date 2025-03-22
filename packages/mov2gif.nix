{ writeShellApplication, ffmpeg }:
writeShellApplication {
  name = "mov2gif";
  runtimeInputs = [ ffmpeg ];
  meta.description = ''
    Convert .mov to .gif format
  '';
  text = ''
    for f in "$@"; do
        name=$(${../scripts/file_name.sh} "$f");
        ${ffmpeg}/bin/ffmpeg -i "$f" -vf "[0:v] fps=30" "./$name.gif";
    done
  '';
}
