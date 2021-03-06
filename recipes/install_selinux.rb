bash "semodule -i sshd_stat_authorized_keys.pp" do
  code <<-CODE
checkmodule -M -m -o sshd_stat_authorized_keys.mod sshd_stat_authorized_keys.te
semodule_package -o sshd_stat_authorized_keys.pp -m sshd_stat_authorized_keys.mod 
semodule -i sshd_stat_authorized_keys.pp
  CODE
  cwd "/tmp"
  action :nothing
end

cookbook_file "/tmp/sshd_stat_authorized_keys.te" do
  source "sshd_stat_authorized_keys.te"
  notifies :run, "bash[semodule -i sshd_stat_authorized_keys.pp]"
end
