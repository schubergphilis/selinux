#
# Cookbook Name:: selinux
# Recipe:: default
#
# Copyright (C) 2015 Schuberg Philis
#
# All rights reserved - Do Not Redistribute
#

extend Chef::Util::Selinux
if selinux_enabled?
  package 'checkpolicy' do
    action :install
  end

  package 'policycoreutils-python' do
    action :install
  end

  selinux_compile 'SELinux_Rules' do
    version 1.0
    seperate_files node['selinux']['seperate_files']
    from_file node['selinux']['compile_from_file']
    se_dir "/etc/selinux/local/selinux_rules.te"
    action :compile
  end
else
  log "SELinux is not enabled"
end
