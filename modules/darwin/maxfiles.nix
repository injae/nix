{ ... }:
{
  # Raise the system-wide open-file (RLIMIT_NOFILE) limit.
  #
  # macOS launches GUI apps via launchd, which seeds each process's soft
  # limit at 256/1024. Emacs on macOS uses the kqueue file-notify backend,
  # which consumes one file descriptor *per watched file* — eglot/gopls
  # watching a large project tree exhausts the limit and triggers
  # "File watching not possible, no file descriptor left".
  #
  # This daemon raises the inherited limit at boot. Actual usage is still
  # capped by the kernel ceiling (kern.maxfilesperproc, 92160 here).
  launchd.daemons.maxfiles = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxfiles"
        "65536"
        "524288"
      ];
      RunAtLoad = true;
      ServiceIPC = false;
    };
  };
}
