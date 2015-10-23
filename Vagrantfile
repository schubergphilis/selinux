# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'
Vagrant.require_version '>= 1.5.0'


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  ['vagrant-berkshelf', 'vagrant-omnibus'].each do |plugin| 
    unless Vagrant.has_plugin?(plugin)
      raise "First install: `$ vagrant plugin install #{plugin}`"
    end
  end

  config.vm.hostname = 'mccx-centos7-selinux'
  config.omnibus.chef_version = 'latest'
  config.vm.synced_folder '.', '/vagrant', type: 'rsync'
  config.berkshelf.enabled = true
  config.berkshelf.only = []
  config.berkshelf.except = []

  config.vm.provision :chef_solo do |chef|
    chef.json = {}
    chef.run_list = [
      'recipe[selinux::default]'
    ]
  end

  if ENV['CS_VM_HOSTNAME']
    config.vm.box = 'cloudstack'
    config.vm.provider :cloudstack do |cloudstack, override|
      # VM Settings
      cloudstack.name = ENV['CS_VM_HOSTNAME']
      cloudstack.ssh_user = ENV['CS_BOOTSTRAP_USER']
      cloudstack.ssh_key =  ENV['CS_BOOTSTRAP_KEY_PATH']
      cloudstack.service_offering_name = ENV['CS_SERVICE_OFFERING_NAME']
      cloudstack.template_name = ENV['CS_TEMPLATE_NAME']
      cloudstack.network_name =  ENV['CS_NETWORK_NAME']
      cloudstack.zone_name = ENV['CS_ZONE_NAME']

      # CloudStack Provider
      cloudstack.host =  ENV['CS_API_HOST']
      cloudstack.api_key = ENV['CS_API_KEY']
      cloudstack.secret_key = ENV['CS_SECRET_KEY']
      cloudstack.scheme = 'https'
      cloudstack.port = 443
      cloudstack.path = '/client/api'
      cloudstack.expunge_on_destroy = 'true'

      # CloudStack Firewall
      cloudstack.network_type = 'Advanced'
      cloudstack.pf_ip_address = ENV['CS_PUBLIC_ADDRESS']
      cloudstack.pf_public_port = ENV['CS_PUBLIC_PORT']
      cloudstack.pf_private_port = 22
      cloudstack.pf_open_firewall = false
      cloudstack.firewall_rules = [
        { :ipaddress => ENV['CS_PUBLIC_ADDRESS'],
          :cidrlist => ENV['CS_FIREWALL_OPEN_TO_CIDR'],
          :protocol => 'tcp',
          :startport => ENV['CS_PUBLIC_PORT'],
          :endport => ENV['CS_PUBLIC_PORT']
        }
      ]
    end
  else
    #
    # TODO
    #  * Add default Vagrant/VirtualBox settings;
    #
  end
end

# EOF
