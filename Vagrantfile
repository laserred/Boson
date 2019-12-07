# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

opts = GetoptLong.new(
  [ '--hostname', GetoptLong::REQUIRED_ARGUMENT ]
)

host_name='boson'

opts.each do |opt, arg|
  case opt
    when '--hostname'
      if arg != ''
        host_name=arg
      end
  end
end


Vagrant.configure("2") do |config|
  
  config.vm.box = "centos/7"
  config.vm.hostname = "#{host_name}"

  ##############
  ### Swap the comment on the below lines to avoid being
  ### asked what network adapter to bind to on boot. Don't
  ### forget to change [adapter] to your adapter name.
  ##############
  config.vm.network "public_network"
  #config.vm.network "public_network", bridge: "[adapter]"

  config.vm.post_up_message = <<-MESSAGE 

   __   __  _______  __   __  __  
  |  | |  ||   _   ||  | |  ||  | 
  |  |_|  ||  |_|  ||  |_|  ||  | 
  |       ||       ||       ||  | 
  |_     _||       ||_     _||__| 
    |   |  |   _   |  |   |   __  
    |___|  |__| |__|  |___|  |__| 

  
  Laser Red Boson is now available at: http://#{host_name}.local


  MESSAGE

  config.vm.synced_folder "www", "/var/www",
    :owner => 'vagrant',
    :group => 'vagrant',
    :mount_options => ['dmode=775', 'fmode=775']

  config.vm.provision "file", source: "templates/phpmyadmin.conf", destination: "/tmp/", run: "once"
  config.vm.provision "shell", path: "scripts/init.sh", env: {"HOST_NAME" => "#{host_name}"}
  config.vm.provision "file", source: "templates/site-nginx.conf", destination: "/tmp/", run: "once"
  config.vm.provision "file", source: "templates/site-phpfpm.conf", destination: "/tmp/", run: "once"
  #config.vm.provision "shell", path: "scripts/site.sh", env: {"HOST_NAME" => "#{host_name}"}

  config.vm.provider "virtualbox" do |vb|
    vb.name = "Boson - #{host_name}"
    vb.memory = "2048"
    vb.customize ['modifyvm', :id, '--uartmode1', 'disconnected']
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  
end
