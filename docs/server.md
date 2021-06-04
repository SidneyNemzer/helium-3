# Instructions for setting up an H3 server

Based on Linode Debian 10

```
ssh root@ip
apt update
apt install ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw enable
# edit /etc/ssh/ssh_config and set `PasswordAuthentication no`
service ssh restart
apt install fail2ban
echo "[DEFAULT]\n\nbantime = 24h\nmaxretry=3\n" > /etc/fail2ban/jail.local
service fail2ban restart
curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt install nodejs
mkdir ~/helium3
```
