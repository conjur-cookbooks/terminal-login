service "ssh" do
  action :enable
end

ruby_block "Configure sshd with AuthorizedKeysCommand" do
  block do
    edit = Chef::Util::FileEdit.new('/etc/ssh/sshd_config')
    
    edit.insert_line_after_match(/#?AuthorizedKeysFile/, '''
AuthorizedKeysCommand     /root/authorized_keys.sh
AuthorizedKeysCommandRunAs root
    ''')
    edit.write_file
    Chef::Log.info "Wrote AuthorizedKeysCommand into sshd_config"
  end
  # This not_if is pretty brittle, for example the centos version of the file
  # has commented out lines that will match, so I'm leaving it out.
  # not_if { File.read('/etc/ssh/sshd_config').index('AuthorizedKeysCommand') }
  notifies :restart, "service[ssh]"
end
