ENV['VAGRANT_DEFAULT_PROVIDER'] = "virtualbox"

Vagrant.configure("2") do |config|
  # Disable synced folders
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  config.vm.provider :virtualbox do |v|
    v.linked_clone = true
  end
  
  # Machine setup
  config.vm.define "pi4b" do |app|
    app.vm.box = "generic/debian12"
    app.vm.hostname = "athena"
    app.vm.network :private_network, ip: "192.168.56.2"

    app.vm.provider :virtualbox do |v|
      v.memory = 4096
      v.cpus = 4
    end
  end
  
  config.vm.define "optiplex" do |app|
    app.vm.box = "generic/debian12"
    app.vm.hostname = "hermes"
    app.vm.network :private_network, ip: "192.168.56.3"

    app.vm.provider :virtualbox do |v|
      v.memory = 16384
      v.cpus = 4
    end
  end
 
  # config.vm.define "controller2" do |app|
  #   app.vm.box = "generic/debian12"
  #   app.vm.hostname = "controller2"
  #   app.vm.network :private_network, ip: "192.168.56.4"
  # end
  #
  # config.vm.define "worker2" do |app|
  #   app.vm.box = "generic/debian12"
  #   app.vm.hostname = "worker2"
  #   app.vm.network :private_network, ip: "192.168.56.5"
  # end


  # Mimic setup of a fresh hardware install
  config.vm.provision "shell", inline: <<-SHELL
     useradd -m -s /bin/bash -U kalex
     usermod -aG sudo kalex
     echo 'kalex:changeme' | chpasswd 
     chown -R kalex:kalex /home/kalex
     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
     systemctl restart sshd.service
  SHELL
end
