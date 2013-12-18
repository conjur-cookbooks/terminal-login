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

ruby_block "Enable DEBUG logging for sshd" do
  block do
    edit = Chef::Util::FileEdit.new('/etc/ssh/sshd_config')
    edit.search_file_replace_line "LogLevel INFO", "LogLevel DEBUG"
    edit.write_file
  end
  not_if { File.read('/etc/ssh/sshd_config').index('LogLevel DEBUG') }
  notifies :restart, "service[ssh]"
end

# Need this because there's not going to be a homedir the first time we 
# login.  Without this the first attempt to ssh to the host will fail.
ruby_block "Tell sshd not to print the last login" do
  block do 
    edit = Chef::Util::FileEdit.new '/etc/ssh/sshd_config'
    edit.search_file_replace_line "PrintLastLog yes", "PrintLastLog no"
    edit.write_file
  end
  not_if{ File.read('/etc/ssh/sshd_config').index 'PrintLastLog no' }
  notifies :restart, "service[ssh]" 
end

%w(nscd nslcd).each{ |s| service s }

# https://github.com/AndreyChernyh/openssh/commit/ee011fdda086547c876bceff79f63d751d0893b9
ssh_service_provider = Chef::Provider::Service::Upstart if 'ubuntu' == node['platform'] && Chef::VersionConstraint.new('>= 13.10').include?(node['platform_version'])

service("ssh") { provider ssh_service_provider }

layer_env = node.conjur.layer_env
config = JSON.parse(File.read('/vagrant/conjur.json'))
namespace = config['namespace']
hostid = "#{namespace}/#{layer_env}/hosts/0"
host_api_key = config["api_keys"]["sandbox:host:#{hostid}"]

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  variables hostid: hostid, host_api_key: host_api_key
  notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end

execute "pam-auth-update" do
  command "pam-auth-update --package"
  notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end

cookbook_file "/etc/sudoers.d/conjurers" do
  source "sudoers.d_conjurers"
end
