# Nix-WSL + Nix-Darwin + Emacs Configuration
- [emacs configuration](./home/programs/emacs/config)

# generate key
```shell
ssh-keygen -t ed25519 -c "${email}"
```

# Add Secrets and PubKey
```shell
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt

sops updatekeys home/programs/sops/secrets/secrets.yaml
```

## macOS 최초 설치용 Nix 정리

nix-darwin이 시스템 Nix와 데몬을 관리해도 최초 설치 프로필의 구버전 Nix는
남을 수 있다. 시스템 Nix가 정상 동작하고 데몬도 nix-darwin에서 관리하는지
확인한 뒤, 최초 설치 프로필에서 Nix만 한 번 제거한다.

```shell
/run/current-system/sw/bin/nix --version
/run/current-system/sw/bin/nix-env \
  --profile /nix/var/nix/profiles/per-user/root/profile --query --installed

sudo /run/current-system/sw/bin/nix-env \
  --profile /nix/var/nix/profiles/per-user/root/profile --uninstall nix
```

이 경로는 `/nix/var/nix/profiles/default`가 가리키는 root 프로필이다.
인증서와 다른 패키지는 유지되며, 이전 세대에 남은 구버전 Nix는 기존 자동
GC의 1주 보존 정책에 따라 다른 참조가 없어졌을 때 정리된다.
전체 Nix 설치를 삭제하는 명령은 아니다.

참고: [nix-env --uninstall](https://nix.dev/manual/nix/2.34/command-ref/nix-env/uninstall.html)

