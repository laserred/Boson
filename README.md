![boson](https://i.imgur.com/J17L54O.jpg)
# Laser Red Boson
Easily setup Magento 2 sites to develop locally

### Required Software
1. VirtualBox
2. Vagrant

*WINDOWS USERS:* https://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user?answertab=votes#125981

### Initial Setup

1. Clone this repo
2. Install guest additions for VirtualBox `vagrant plugin install vagrant-vbguest`
3. Start the VM `vagrant --host=[hostname] up` (this will default to boson)

### Usage

1. Start the VM `vagrant --host=[hostname] up`
2. Copy or clone your git repo into your sites local directory, if you're working on an exising project
3. Import your DB using phpMyAdmin (remember to replace your site URL's)

### Info

Local file webroot will be at www/[hostname]

Site will be served from http://[hostname].local

phpMyAdmin is available from port 8080 (http://[hostname].local:8080)

**Built with love by the team at [Laser Red](https://laser.red)**
