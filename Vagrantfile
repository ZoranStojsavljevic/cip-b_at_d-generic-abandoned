# Copyright (C) 2016-2017, Siemens AG, Wolfgang Mauerer <wolfgang.mauerer@siemens.com>
# Copyright (C) 2016-2017, Codethink, Ltd., Robert Marshall <robert.marshall@codethink.co.uk>
# Copyright (C) 2018-2018, Siemens AG, Zoran Stojsavljevic <zoran.stojsavljevic@gmail.com>
# SPDX-License-Identifier:	AGPL-3.0
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

## Ensuring the plugins are installed
##
## There is no built-in vagrant command to make sure that a plugin is installed but since the Vagrantfile is a Ruby file, it is very easy to write a little bit of Ruby code to ensure that the plugin is installed.
##
## In the Vagrantfile before the Vagrant.configure(2) do |config| line added the following code snippet:

## =begin
$build = <<SCRIPT
cd /vagrant
set -e
integration-scripts/install_ifupdown_workaround.sh
integration-scripts/install_dependencies.sh
integration-scripts/install_backend.sh
integration-scripts/install_frontend.sh
integration-scripts/install_build_script.sh
integration-scripts/configure_singledev.sh
integration-scripts/install_lava.sh
integration-scripts/configure_lava.sh
SCRIPT
## =end

# Helper functions placed here!
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  end
  return nil
end

def usbfilter_exists(vendor_id, product_id)
  # Determine if a usbfilter with the provided Vendor/Product ID combination
  # already exists on this VM.
  # NOTE: The "machinereadable" output for usbfilters is more
  #       complicated to work with (due to variable names including
  #       the numeric filter index) so we don't use it here.
  #
  machine_id_filepath = File.join(".vagrant", "machines", "default", "virtualbox", "id")

  if not File.exists? machine_id_filepath
    # VM hasn't been created yet.
    return false
  end

  machine_id = File.read(machine_id_filepath)

  vm_info = `VBoxManage showvminfo #{machine_id}`
  filter_match = "VendorId:         #{vendor_id}\nProductId:        #{product_id}\n"
  
  return vm_info.include? filter_match
end

def better_usbfilter_add(vb, vendor_id, product_id, filter_name)
  # This is a workaround for the fact VirtualBox doesn't provide
  # a way for preventing duplicate USB filters from being added.
  #
  # TODO: Implement this in a way that it doesn't get run multiple
  #       times on each Vagrantfile parsing.
  if not usbfilter_exists(vendor_id, product_id)
    vb.customize ["usbfilter", "add", "0",
                  "--target", :id,
                  "--name", filter_name,
                  "--vendorid", vendor_id,
                  "--productid", product_id
                  ]
  end
end

Vagrant.configure(2) do |config|
  config.vm.provider :virtualbox do |vbox, override|
    config.vm.box = "debian/stretch64"
    config.vm.box_check_update = true

    ## vagrant plugin install vagrant-vbguest
    ## vagrant-vbguest: a vagrant plugin to keep VirtualBox Guest Additions up to date
    if !Vagrant.has_plugin?("vagrant-vbguest")
      system('vagrant plugin install vagrant-vbguest')

      raise("vagrant-vbguest installed. Run command again.");
    end

    vbox.customize ["modifyvm", :id, "--vram", "128"]
    vbox.customize ["modifyvm", :id, "--memory", "4096"]
    vbox.customize ["modifyvm", :id, "--cpus", "2"]
    vbox.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vbox.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]

    vbox.customize ["modifyvm", :id, "--usb", "on"]
    vbox.customize ["modifyvm", :id, "--usbehci", "on"]

    ## Old usbfilter_add interface, obsolete
    ## better_usbfilter_add(vbox, "ASIX Electronics Corp. AX88772 [0001]", "0B95", "7720", "AX88772")

    ## VBox passthrough for the USB/ETH device for DUT 
    better_usbfilter_add(vbox, "0B95", "7720", "ASIX Electronics Corp. AX88772 [0001]")

    ## VBox passthrough for USB2SER for BBB01 DUT
    better_usbfilter_add(vbox, "067B", "2303", "USB-Serial Controller")

    ## VBox passthrough for USB2SER for iwg20m DUT
    better_usbfilter_add(vbox, "0403", "6001", "FTDI FT232R USB UART [0600]")
  end

  ## Common stuff, independept of the "any" Virtual Provider used!

  ## system('vagrant plugin install vagrant-proxyconf')
  if !Vagrant.has_plugin?("vagrant-proxyconf")
    system('vagrant plugin install vagrant-proxyconf')

    raise("vagrant-proxyconf installed. Run command again.");
  end

  if Vagrant.has_plugin?("vagrant-proxyconf")
  ## =begin ## multicomment way in Ruby, with tuple: {=begin ; =end}
    config.proxy.http     = "http://194.145.60.1:9400/"
    config.proxy.https    = "http://194.145.60.1:9400/"
    config.proxy.ftp      = "http://194.145.60.1:9400/"
    ## config.proxy.all      = "http://194.145.60.1:9400/"
    config.proxy.no_proxy = "localhost,127.0.0.1,.siemens.com,.siemens.de,.siemens.net,.siemens.rocks,.siemens.io,.saacon.net"
  ## =end
  end

  ## Vagrant network configuration ==>> MUST stay as original!?

  # Forward port 8888 for the internal REST server
  config.vm.network :forwarded_port, guest: 8888, host: 8888
  ## Forward port 8020 for the ser2net terminal
  ## config.vm.network :forwarded_port, guest: 8020, host: 8020
  # Forward port 8010 for the Storage Server
  config.vm.network :forwarded_port, guest: 8010, host: 8010
  # Forward port 5000 for the KernelCI Frontend Web Server
  config.vm.network :forwarded_port, guest: 5000, host: 5000
  # Forward port 80 for the http Lava Frontend Web Server
  config.vm.network :forwarded_port, guest: 8080, host: 8080
  # Forward port 443 for the https Lava Frontend Web Server
  config.vm.network :forwarded_port, guest: 443, host: 4443
  # Configure network accessibility for tftp server
  config.vm.network "public_network", use_dhcp_assigned_default_route: true

=begin
  ## Run Ansible from the Vagrant Host
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./private-net/copy-vm.yml"
    ansible.verbose = "vvv"
  end

  ## default router to be static private network, based on eth2
  config.vm.provision "shell",
    run: "always",
    inline: "ifconfig eth1 down"

  config.vm.provision "shell",
    run: "always",
    inline: "ip route delete default"

  config.vm.provision "shell",
    run: "always",
    inline: "ip route add default via 192.168.15.1 dev eth2"
=end

=begin
  config.vm.provision "shell" do |s|
    s.privileged = false
    s.inline = $build
  end
=end

  $script_true = "/bin/bash /vagrant/private-net/test.sh"
  config.vm.provision :shell, privileged: true, inline: $script_true

  ## config.vm.provision :shell, :path => "/vagrant/private-net/test.sh", privileged: true

  config.vm.synced_folder ".", "/vagrant", type: "rsync"
end
