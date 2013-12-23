case node[:platform]
  when 'ubuntu', 'fedora', 'debian' 
    include_recipe 'pam-ldap::ubuntu'
  when 'centos', 'redhat', 'fedora'
    include_recipe 'pam-ldap::centos'
  else
    raise "unsupported platform: #{node[:platform]}"
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
