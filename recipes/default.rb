include_recipe "sshd-service"

remote_directory '/var/chef'

group "conjurers" do
  gid 50000
end

group "users" do
  gid 5000
end

# Answer the installer questions about LDAP server location, root name, etc
cookbook_file "/tmp/ldap.seed" do
  source "ldap.seed"
end

cookbook_file "/usr/share/pam-configs/mkhomedir" do
  source "mkhomedir"
end

execute "debconf-set-selections /tmp/ldap.seed"

for pkg in %w(debconf nss-updatedb nscd libpam-mkhomedir auth-client-config ldap-utils ldap-client libpam-ldapd libnss-ldapd)
  package pkg do
    options "-qq"
  end
end

execute "pam-auth-update" do
  command "pam-auth-update --package"
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end

# Set up sudoers
cookbook_file "/etc/sudoers.d/conjurers" do
  source "sudoers.d_conjurers"
end

package "curl"

ruby_block "Enable DEBUG logging for sshd" do
  block do
    edit = Chef::Util::FileEdit.new('/etc/ssh/sshd_config')
    edit.search_file_replace_line "LogLevel INFO", "LogLevel DEBUG"
    edit.write_file
  end
  # Ommitting flakey/brittle not_if 
  # not_if { File.read('/etc/ssh/sshd_config').index('LogLevel DEBUG') }
  notifies :restart, "service[#{node.sshd_service.service}]"
end

# Need this because there's not going to be a homedir the first time we 
# login.  Without this the first attempt to ssh to the host will fail.
ruby_block "Tell sshd not to print the last login" do
  block do
    edit = Chef::Util::FileEdit.new '/etc/ssh/sshd_config'
    edit.search_file_replace_line "PrintLastLog yes", "PrintLastLog no"
    edit.write_file
  end
  # Ommiting flakey and brittle not_if
  # not_if{ File.read('/etc/ssh/sshd_config').index 'PrintLastLog no' }
  notifies :restart, "service[#{node.sshd_service.service}]"
end

%w(nscd nslcd).each{|s| service s}