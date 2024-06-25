{ bazel_7
, fetchurl
, version
, dist_sha
, lock_sha
}:
(bazel_7.override { version = "${version}"; }).overrideAttrs
{
  version = "${version}";
  src = fetchurl {
    url = "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel-${version}-dist.zip";
    hash = "${dist_sha}";
  };
  lockfile = fetchurl {
    url = "https://raw.githubusercontent.com/bazelbuild/bazel/release-${version}/MODULE.bazel.lock";
    sha256 = "${lock_sha}";
  };
}
