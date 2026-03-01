## install
```bash
mkdir -p ~/.local/bin && \
curl -fsSL https://raw.githubusercontent.com/awkirin/awk-git-sops/refs/heads/main/awk-git-sops.sh -o ~/.local/bin/awk-git-sops && \
chmod +x ~/.local/bin/awk-git-sops && \
git config --global alias.encrypt '!~/.local/bin/awk-git-sops.sh encrypt' && \
git config --global alias.decrypt '!~/.local/bin/awk-git-sops.sh decrypt'
```
