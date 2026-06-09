# HOWTO

1. install container: `brew install container`
2. start the process: `container system start`
3. build the image: `container build --platform linux/amd64 -t vibe-sandbox:latest .`
4. move to your project folder and start the container: `start.sh`
5. prepare your project, i.e.: `mise install && pnpm install`
6. login to github `gh auth login`
7. start claude `claude --dangerously-skip-permissions`
8. login to claude `/login`
