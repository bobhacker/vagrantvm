Vagrant.configure("2") do |config|
  config.vm.box = "geerlingguy/ubuntu1604"
  config.vm.define "vagrantvm"
  config.vm.hostname = "vagrantvm.dev"
  config.vm.network "private_network", ip: "192.168.55.55"
  config.vm.provider "virtualbox" do |v|
    v.name = "vagrantvm.dev"
    v.memory = 2048
    v.cpus = 1
  end
  config.vm.provision "shell", path: "provisioning/provision.sh"
  config.vm.synced_folder "www/", "/var/www/html"
end
