![boson](https://i.imgur.com/J17L54O.jpg)
# Laser Red Boson
Easily setup Magento 2 sites to develop locally

### Initial Install

1. Clone this repo
2. `vagrant --hostname=[hostname] up` (this will default to boson)

### Setup a new site

1. Start the VM `vagrant --hostname=[hostname] up`
2. SSH into the VM `vagrant ssh`
3. Navigate to your sites webroot `cd /var/www/[hostname].local/htdocs/`
4. Install Magento `composer install`
   1. For your first site it may ask for your Magento API auth details, follow the prompted URL to get these.
5. Start development!

### Info

Local file webroot will be at www/[hostname].local

Site will be served from http://[hostname].local

**Built with love by the team at [Laser Red](https://laser.red)**