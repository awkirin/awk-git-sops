## install
```bash
mkdir -p ~/.local/bin && \
curl -fsSL https://raw.githubusercontent.com/awkirin/awk-sops/refs/heads/main/awk-sops.sh -o ~/.local/bin/awk-sops && \
chmod +x ~/.local/bin/awk-sops && \
git config --global alias.encrypt '!~/.local/bin/awk-sops encrypt' && \
git config --global alias.decrypt '!~/.local/bin/awk-sops decrypt'
```
