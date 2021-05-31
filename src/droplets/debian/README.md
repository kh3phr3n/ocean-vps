### Debian-ocean

Minimal script for set up Debian on DigitalOcean

#### Minimal system setup

```bash
# Prepare zx utility
wget -qO - https://raw.githubusercontent.com/kh3phr3n/ocean-vps/master/src/droplets/debian/prepare.sh | bash

# Setup system
wget https://raw.githubusercontent.com/kh3phr3n/ocean-vps/master/src/droplets/debian/install.mjs

# Don't forget to edit constants
zx install.sh
```
