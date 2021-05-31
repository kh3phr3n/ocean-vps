#!/bin/bash

# Update system
apt update && apt upgrade

# Install NodeJS
wget -qO - https://deb.nodesource.com/setup_lts.x | bash \
    && apt install -y nodejs \
    && npm install -g zx
