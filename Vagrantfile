# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

opts = GetoptLong.new(
  [ '--hostname', GetoptLong::REQUIRED_ARGUMENT ]
)

host_name='boson'

customParameter=''

opts.each do |opt, arg|
  case opt
    when '--hostname'
      if arg == ''
        host_name=boson
      else
        host_name=arg
      end
  end
end


Vagrant.configure("2") do |config|
  
  config.vm.box = "centos/7"
  config.vm.hostname = "#{host_name}"
  config.vm.network "public_network"
  #config.vm.network "forwarded_port", guest: 22, host: 2222, host_ip: "127.0.0.1", id: 'ssh'
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
        :group => 'www-data',
        :mount_options => ['dmode=775', 'fmode=775']

  config.vm.provision "shell", inline: "sudo service nginx restart", run: "always"
  config.vm.provision "shell", path: "scripts/init.sh"
  config.vm.provision "shell", path: "scripts/site.sh", env: {"HOST_NAME" => "#{host_name}"}

  config.vm.provider "virtualbox" do |vb|
    vb.name = "Higgs - #{host_name}"
    vb.memory = "2048"
    vb.customize ['modifyvm', :id, '--uartmode1', 'disconnected']
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  
end
