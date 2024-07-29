{ super }:
{ version
, distHash ? super.lib.fakeSha256
, lockHash ? super.lib.fakeSha256
, overrideAttrs ? { }
}:
(super.bazel_7.override { inherit version; } // overrideAttrs
).overrideAttrs
  (rec {
    inherit version;
    src = super.fetchurl {
      url = "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel-${version}-dist.zip";
      hash = distHash;
    };
    lockfile = super.fetchurl {
      url = "https://raw.githubusercontent.com/bazelbuild/bazel/release-${version}/MODULE.bazel.lock";
      sha256 = lockHash;
    };
  })
