{ podman-unwrapped
, runCommand
, makeWrapper
, lib
, stdenv
, extraPackages ? []
, podman # Docker compat
, runc # Default container runtime
, crun # Container runtime (default with cgroups v2 for podman/buildah)
, conmon # Container runtime monitor
, slirp4netns # User-mode networking for unprivileged namespaces
, fuse-overlayfs # CoW for images, much faster than default vfs
, util-linux # nsenter
, cni-plugins # not added to path
, iptables
, iproute2
, qemu
, xz
}:

let
  podman = podman-unwrapped;

  binPath = lib.makeBinPath ([ ] ++ lib.optionals stdenv.isLinux [
    runc
    crun
    conmon
    slirp4netns
    fuse-overlayfs
    util-linux
    iptables
    iproute2
  ] ++ lib.optionals stdenv.isDarwin [
    qemu
    xz
  ] ++ extraPackages);

in runCommand podman.name {
  name = "${podman.pname}-wrapper-${podman.version}";
  inherit (podman) pname version passthru;

  preferLocalBuild = true;

  meta = builtins.removeAttrs podman.meta [ "outputsToInstall" ];

  outputs = [
    "out"
    "man"
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

} ''
  ln -s ${podman.man} $man

  mkdir -p $out/bin
  ln -s ${podman-unwrapped}/etc $out/etc
  ln -s ${podman-unwrapped}/lib $out/lib
  ln -s ${podman-unwrapped}/share $out/share
  makeWrapper ${podman-unwrapped}/bin/podman $out/bin/podman \
    --prefix PATH : ${binPath}
''
