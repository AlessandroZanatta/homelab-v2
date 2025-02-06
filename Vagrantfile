iso_path = Dir.getwd + "/images/metal-amd64.iso"

Vagrant.configure("2") do |config|
  config.vm.define "control-plane" do |vm|
    vm.vm.provider :libvirt do |domain|
      domain.cpus = 4
      domain.memory = 8192
      domain.storage :file, :device => :cdrom, :path => iso_path 
      domain.storage :file, :size => '20G', :type => 'raw'
      domain.boot 'hd'
      domain.boot 'cdrom'
    end
  end

  config.vm.define "worker" do |vm|
    vm.vm.provider :libvirt do |domain|
      domain.cpus = 4
      domain.memory = 8192
      domain.storage :file, :device => :cdrom, :path => iso_path 
      domain.storage :file, :size => '20G', :type => 'raw'
      domain.boot 'hd'
      domain.boot 'cdrom'
    end
  end
end
