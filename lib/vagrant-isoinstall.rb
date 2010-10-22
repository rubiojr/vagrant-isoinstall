require 'vagrant'
require 'vagrant/ui'
require 'vagrant/downloaders/http'
require 'fileutils'

class ISOInstallCMD < Vagrant::Command::Base
  class_option :url, :type => :string, :optional => false 
  class_option :name, :type => :string, :optional => true, :default => 'vagrant-foo'
  class_option :memory, :type => :string, :optional => true, :default => 360
  class_option :disk_size , :type => :string, :optional => true, :default => 20000
  class_option :nogui, :type => :boolean, :optional => true, :default => false

  register "isoinstall", "Download an ISO and install from it"

  def execute
    url = options[:url]
    if url.nil?
      env.ui.error '--url option required'
      exit
    end
    disk = "#{ENV['HOME']}/.VirtualBox/HardDisks/#{options[:name]}.vmdk"
    vmname = options[:name]
    if not VirtualBox::VM.find(vmname).nil?
      env.ui.error "Virtual Machine #{vmname} already exists. Choose a different name."
      exit
    end
    memory = options[:memory]
    disk_size = options[:disk_size]
    iso_cache_dir = ENV["HOME"] + '/.vagrant/cache/isos'
    FileUtils.mkdir_p iso_cache_dir if not File.exist?(iso_cache_dir)
    cdrom = "#{iso_cache_dir}/last_iso"

    env.ui.info "Downloading ISO..."
    downloader = Vagrant::Downloaders::HTTP.new env
    downloader.download! url, File.new(cdrom, 'w')
    env.ui.info "Creating VM..."
    vboxmanage "createvm --name #{vmname} --register"
    vboxmanage "modifyvm #{vmname} --memory #{memory}"
    vboxmanage "storagectl #{vmname} --name ide-controller --add ide"

    env.ui.info "Creating Disk..."
    vboxmanage "createhd --filename #{disk} --size #{disk_size} --format VMDK --variant Stream"
    vboxmanage "storageattach #{vmname} --storagectl ide-controller --port 0 --device 0 --type hdd --medium #{disk}"
    vboxmanage "storageattach #{vmname} --storagectl ide-controller --port 0 --device 1 --type dvddrive --medium #{cdrom}"

    env.ui.info "Starting VM..."
    if options[:nogui]
      vboxmanage "startvm  --type headless #{vmname}"
    else
      vboxmanage "startvm  --type gui #{vmname}"
    end
  end

  private
  def vboxmanage(args)
    @last_output = `VBoxManage #{args} 2>&1`
    @last_status = $?
  end

end

