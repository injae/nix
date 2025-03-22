{
  writeShellApplication,
  yt-dlp,
  ffmpeg,
}:
writeShellApplication {
  name = "dl-yt-mp3";
  runtimeInputs = [
    yt-dlp
    ffmpeg
  ];
  meta.description = ''
    Download youtube video as mp3 file
  '';
  text = ''
    for url in "$@"; do
        ${yt-dlp}/bin/yt-dlp -x --audio-format mp3 --audio-quality 0 --ffmpeg-location ${ffmpeg}/bin/ffmpeg -P "./" "$url"
    done
  '';
}
