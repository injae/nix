{ writeShellApplication, yt-dlp }:
writeShellApplication {
  name = "dl-yt";
  runtimeInputs = [ yt-dlp ];
  meta.description = ''
    Download youtube video
  '';
  text = ''
    for url in "$@"; do
        ${yt-dlp}/bin/yt-dlp -P "./" "$url"
    done
  '';
}
