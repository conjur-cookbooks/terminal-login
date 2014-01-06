%w(nscd nslcd).each do |s| 
  service s do
    action :enable
  end
end

account = node.conjur.account
stack = node.conjur.stack
uri = case stack
when 'ci'
  'ldap://ldap-server-1050080273.us-east-1.elb.amazonaws.com:1389'
else
  'ldap://ldap.conjur.ws:1389'
end

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  gid = case node[:platform]
    when 'ubuntu', 'debian' then 'nslcd'
    when 'centos', 'redhat' then 'ldap'
    else raise "Unsupported platform: #{node[:platform]}"
  end
  variables account: account, host_id: node.conjur.host_identity.id, host_api_key: node.conjur.host_identity.api_key, gid: gid, uri: uri
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end

template "/root/authorized_keys.sh" do
  source "authorized_keys.sh.erb"
  variables account: account
  mode "0700"
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end
