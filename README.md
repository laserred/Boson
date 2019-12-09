![boson](https://i.imgur.com/J17L54O.jpg)
# Laser Red Boson
Easily setup Magento 2 sites to develop locally

### Initial Setup

1. Clone this repo
2. Install guest additions for VirtualBox `vagrant plugin install vagrant-vbguest`
3. Start the VM `vagrant --hostname=[hostname] up` (this will default to boson)

### Usage

1. Start the VM `vagrant --hostname=[hostname] up`
2. Copy or clone your git repo into your sites local directory, if you're working on an exising project
3. Import your DB using phpMyAdmin (remember to replace your site URL's)

### Info

Local file webroot will be at www/[hostname]

Site will be served from http://[hostname].local

phpMyAdmin is available from port 8080 (http://[hostname].local:8080)

**Built with love by the team at [Laser Red](https://laser.red)**