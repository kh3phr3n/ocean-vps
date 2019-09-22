### Freebsd-ocean
Minimal script for setup FreeBSD on DigitalOcean

```bash
# Update the entire system
sudo sh -c 'freebsd-update fetch install && pkg update && pkg upgrade'

# Update shell to Bash
sudo sh -c 'pkg install bash bash-completion && chsh -s /usr/local/bin/bash freebsd'

# Reboot system
sudo shutdown -r now
```

#### Minimal system setup

```bash
wget https://raw.githubusercontent.com/kh3phr3n/ocean-vps/master/src/droplets/freebsd/setup.sh
sudo sh -c 'chmod +x setup.sh && ./setup.sh'
```

#### Good information

* [Introduction to FreeBSD for Linux users][1]
* [How to get started with FreeBSD][2]
* [Recommended steps for a new FreeBSD server][3]
* [Basic introduction to FreeBSD maintenance][4]
* [Manage Packages on FreeBSD][5]
* [How to install a FAMP stack on FreeBSD][6]
* [How to Install Nginx on FreeBSD][7]
* [How To Secure Nginx with Let's Encrypt on FreeBSD][8]
* [FreeBSD Install Nginx Webserver Tutorial][9]
* [FreeBSD Install PHP 7.2 with FPM for Nginx][10]
* [FreeBSD Install MariaDB Databases on Unix Server][11]

[1]: https://www.digitalocean.com/community/tutorials/a-comparative-introduction-to-freebsd-for-linux-users
[2]: https://www.digitalocean.com/community/tutorials/how-to-get-started-with-freebsd
[3]: https://www.digitalocean.com/community/tutorials/recommended-steps-for-new-freebsd-12-0-servers
[4]: https://www.digitalocean.com/community/tutorials/an-introduction-to-basic-freebsd-maintenance
[5]: https://www.digitalocean.com/community/tutorials/how-to-manage-packages-on-freebsd-10-1-with-pkg
[6]: https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0
[7]: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-freebsd-11-2
[8]: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-letsencrypt-freebsd
[9]: https://www.cyberciti.biz/faq/freebsd-install-nginx-webserver
[10]: https://www.cyberciti.biz/faq/freebsd-install-php-7-2-with-fpm-for-nginx
[11]: https://www.cyberciti.biz/faq/how-to-install-mariadb-databases-on-a-freebsd-v10-unix-server

