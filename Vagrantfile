require 'yaml'

HOSTNAME = "kubespray-vagrant"
BOX_IMAGE = "bento/ubuntu-20.04"

if File.exist?('config.yml')
  CONFIG_YAML = YAML.load_file('config.yml')
else
  CONFIG_YAML = YAML.load_file('config.yml.default')
end


Vagrant.configure("2") do |config|
  config.vm.define HOSTNAME
  config.vm.hostname = HOSTNAME
  config.vm.box = BOX_IMAGE

  config.vm.provider "virtualbox" do |v|
    v.cpus = CONFIG_YAML["cpus"]
    v.memory = CONFIG_YAML["memory_mb"]
  end

  config.vm.network "private_network", ip: CONFIG_YAML["address"]
  config.vm.network "forwarded_port", id: "ssh", guest: 22, host: CONFIG_YAML["ssh_forward_port"]

  config.vm.provision "shell", path: "provision.sh", env: {IP: CONFIG_YAML["address"], APT_REGION: CONFIG_YAML["apt_region"]}
  config.vm.provision "shell", path: "monitoring.sh"
end
