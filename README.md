# PAIRS Lab apt repository

A public, signed apt repository for PAIRS ROS packages, served over GitHub Pages.
Once published at `https://thanhnguyencanh.github.io/apt/`, anyone can install PAIRS
packages **by name**:

## For users

### ROS 1 Noetic (Ubuntu 20.04)
```bash
# add the PAIRS repo + signing key (one time)
curl -fsSL https://thanhnguyencanh.github.io/apt/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/pairs.gpg
echo "deb [signed-by=/usr/share/keyrings/pairs.gpg] https://thanhnguyencanh.github.io/apt noetic main" \
  | sudo tee /etc/apt/sources.list.d/pairs.list
sudo apt update

# then install by name
sudo apt install ros-noetic-pairs-msgs
sudo apt install ros-noetic-pairs-lib
```

### ROS 2 Jazzy (Ubuntu 24.04)
```bash
curl -fsSL https://thanhnguyencanh.github.io/apt/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/pairs.gpg
echo "deb [signed-by=/usr/share/keyrings/pairs.gpg] https://thanhnguyencanh.github.io/apt jazzy main" \
  | sudo tee /etc/apt/sources.list.d/pairs.list
sudo apt update

sudo apt install ros-jazzy-pairs-msgs
sudo apt install ros-jazzy-pairs-lib
```

> ROS packages also need the official ROS apt source configured (for `roscpp`,
> `std_msgs`, … dependencies) — i.e. a normal ROS Noetic / Jazzy install.

---

## For maintainers

### Layout
```
pairs-apt/
├── tools/          # repo generator (Docker): Dockerfile, generate.sh, build.sh
├── debs/           # INPUT: drop new .deb files here (gitignored)
├── keys/           # signing key (private.asc) — gitignored, NEVER commit
└── docs/           # OUTPUT: the static, signed apt site published by Pages
```

### Add a package or a new version
```bash
# 1. build the .deb(s) for the package (see each package's packaging/ dir),
#    then drop them into debs/
cp /path/to/ros-noetic-pairs-foo_*.deb  debs/
cp /path/to/ros-jazzy-pairs-foo_*.deb   debs/

# 2. regenerate + re-sign the repo
./tools/build.sh

# 3. commit and push — Pages redeploys automatically
git add docs && git commit -m "publish pairs_foo 1.2.3" && git push
```
The `.deb` filename's distro token routes it to a suite: `*focal*` → `noetic`,
`*noble*` → `jazzy`. Bump each package's `<version>` so apt sees an upgrade.

### Signing key
- On first `./tools/build.sh`, a 4096-bit RSA key is generated and saved to
  `keys/private.asc`. **Keep this file safe and never commit it** (it is
  gitignored). Anyone with it can sign packages as PAIRS Lab.
- The matching public key is published at `docs/KEY.gpg` for users to import.
- To rebuild on another machine / in CI, restore `keys/private.asc` first
  (e.g. from a password manager or a GitHub Actions secret).

---

## One-time GitHub setup

1. Create an empty repo **`thanhnguyencanh/apt`** on GitHub.
2. Push this directory to it (see commands printed after `git init`).
3. Repo **Settings → Pages → Build and deployment → Deploy from a branch**,
   select **`main`** branch and **`/docs`** folder, Save.
4. After a minute the repo is live at `https://thanhnguyencanh.github.io/apt/`.

Verify:
```bash
curl -fsSL https://thanhnguyencanh.github.io/apt/dists/noetic/Release | head
```
