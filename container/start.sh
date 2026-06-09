container run --rm -it \
  --platform linux/amd64 \
  --memory 8g \
  --volume "$PWD:/workspace" \
  --volume "$HOME/.claude:/home/agent/.claude" \
  --volume "$HOME/.claude.json:/home/agent/.claude.json" \
  --workdir /workspace \
  vibe-sandbox:latest \
  bash -lc 'mise trust --yes || true; exec bash'