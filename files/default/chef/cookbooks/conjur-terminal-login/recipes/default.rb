%w(nscd nslcd).each do |s| 
  service s do
    action :enable
  end
end


if node.conjur.terminal_login.ssl_certificate
  cacertfile = "/etc/openldap/cacerts/conjur.pem"
  
  file cacertfile do
    content node.conjur.terminal_login.ssl_certificate
    mode "0644"
  end
else
  cacertfile = nil
end

template "/etc/openldap/ldap.conf" do
  source "ldap.conf.erb"
  variables account: node.conjur.account,
    host_id: node.conjur.host_identity.id,
    uri: node.conjur.terminal_login.ldap_url,
    cacertfile: cacertfile
  mode "0644"
end

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  gid = case node[:platform]
    when 'ubuntu', 'debian' then 'nslcd'
    when 'centos', 'redhat' then 'ldap'
    else raise "Unsupported platform: #{node[:platform]}"
  end
  variables account: node.conjur.account, 
    host_id: node.conjur.host_identity.id, 
    host_api_key: node.conjur.host_identity.api_key, 
    gid: gid, 
    uri: node.conjur.terminal_login.ldap_url,
    cacertfile: cacertfile
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end

curl_options = []
curl_options << "--cacert /etc/openldap/cacerts/conjur.pem" if cacertfile

template "/root/authorized_keys.sh" do
  source "authorized_keys.sh.erb"
  variables uri: node.conjur.terminal_login.authorized_keys_command_url, options: curl_options.join(' ')
  mode "0700"
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end
