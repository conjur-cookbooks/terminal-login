%w(nscd nslcd).each do |s| 
  service s do
    action :enable
  end
end

account = ConjurTerminalLogin.account
authorized_keys_command_url = ConjurTerminalLogin.authorized_keys_command_url(node)
ldap_url = ConjurTerminalLogin.ldap_url(node)

if File.exists?("/opt/conjur/embedded/ssl/certs/conjur.pem")
  cacertfile = "/opt/conjur/embedded/ssl/certs/conjur.pem"
else
  cacertfile = nil
end

openldap_dir = case node[:platform_family]
  when 'debian'
    '/etc/ldap'
  when 'rhel'
    '/etc/openldap'
  else 
    raise "Unsupported platform family : #{node[:platform_family]}"
end

template "#{openldap_dir}/ldap.conf" do
  source "ldap.conf.erb"
  variables account: account,
    host_id: node.conjur.host_identity.id,
    uri: ldap_url,
    cacertfile: cacertfile
  mode "0644"
end

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  gid = case node[:platform_family]
    when 'debian'
      'nslcd'
    when 'rhel'
      'ldap'
    else 
      raise "Unsupported platform family : #{node[:platform_family]}"
  end
  variables account: account, 
    host_id: node.conjur.host_identity.id, 
    host_api_key: node.conjur.host_identity.api_key, 
    gid: gid, 
    uri: ldap_url,
    cacertfile: cacertfile
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end

curl_options = []
curl_options << "--cacert /opt/conjur/embedded/ssl/certs/conjur.pem" if cacertfile

template "/usr/local/bin/conjur_authorized_keys" do
  source "conjur_authorized_keys.sh.erb"
  variables uri: authorized_keys_command_url, options: curl_options.join(' ')
  mode "0755"
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end
