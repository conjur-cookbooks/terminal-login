%w(nscd nslcd).each do |s| 
  service s do
    action :enable
  end
end

hostid = data_bag_item('conjur', 'host')['login']
host_api_key = data_bag_item('conjur', 'host')['api_key']
account = data_bag_item('conjur', 'host')['account']

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  gid = case node[:platform]
    when 'ubuntu', 'debian' then 'nslcd'
    when 'centos', 'redhat' then 'ldap'
    else raise "Unsupported platform: #{node[:platform]}"
  end
  variables hostid: hostid, host_api_key: host_api_key, gid: gid
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end

template "/root/authorized_keys.sh" do
  source "authorized_keys.sh.erb"
  variables account: account
  mode "0700"
end
