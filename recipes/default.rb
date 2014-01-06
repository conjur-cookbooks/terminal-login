include_recipe "sshd-service"

%w(nscd nslcd).each{|s| service s}

remote_directory '/var/chef'

group "conjurers" do
  gid 50000
end

group "users" do
  gid 5000
end

case node[:platform]
  when 'ubuntu', 'debian' 
    include_recipe 'pam-ldap::ubuntu'
  when 'centos', 'redhat'
    include_recipe 'pam-ldap::centos'
  else
    raise "unsupported platform: #{node[:platform]}"
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
  notifies :restart, "service[#{node.sshd_service.service}]"
end

ssh_version = `ssh -v 2>&1`.split("\n")[0]
raise "Can't detect ssh version" unless ssh_version && ssh_version =~ /OpenSSH_([\d\.]+)/
ssh_version = $1

run_as_option = case ssh_version
  when '6.0'
    'AuthorizedKeysCommandRunAs'
  else
    'AuthorizedKeysCommandUser'
end

ruby_block "Configure sshd with AuthorizedKeysCommand" do
  block do
    edit = Chef::Util::FileEdit.new('/etc/ssh/sshd_config')
    
    edit.insert_line_after_match(/#?AuthorizedKeysFile/, <<-CMD)
AuthorizedKeysCommand /root/authorized_keys.sh
#{run_as_option} root
    CMD
    edit.write_file
    Chef::Log.info "Wrote AuthorizedKeysCommand into sshd_config"
  end
  # Need this so the lines don't get inserted multiple times
  not_if { File.read('/etc/ssh/sshd_config').index('AuthorizedKeysCommand /root/authorized_keys.sh') }
  notifies :restart, "service[#{node.sshd_service.service}]"
end

