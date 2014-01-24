default['conjur']['terminal_login']['ldap_url'] = case node['conjur']['stack']
when 'ci'
  'ldap://ldap-server-1050080273.us-east-1.elb.amazonaws.com:1389'
else
  'ldap://ldap.conjur.ws:1389'
end

default['conjur']['terminal_login']['authorized_keys_command_url'] = "https://pubkeys-#{node['conjur']['account']}-conjur.herokuapp.com"
default['conjur']['terminal_login']['ssl_certificate'] = nil
