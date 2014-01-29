default['conjur']['terminal_login']['groupnames']['conjurers'] = 'conjurers'
default['conjur']['terminal_login']['groupnames']['users'] = 'users'
default['conjur']['terminal_login']['debug'] = false
default['conjur']['terminal_login']['ldap_url'] = case node['conjur']['stack']
when 'ci'
  'ldap://ldap-server-1050080273.us-east-1.elb.amazonaws.com:1389'
else
  'ldap://ldap.conjur.ws:1389'
end

