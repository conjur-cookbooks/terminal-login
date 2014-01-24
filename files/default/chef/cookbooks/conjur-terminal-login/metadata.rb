name              'conjur-terminal-login'
maintainer        'Conjur, Inc.'
maintainer_email  'kgilpin@conjur.net'
license           'Apache 2.0'
description       'Configures ssh and nslcd for Conjur PAM+LDAP'
version           '0.1.0'

%w(ubuntu debian centos fedora).each do |platform|
  supports platform
end

attribute "conjur/terminal_login/ldap_url", description: "URL of the LDAP server"
attribute "conjur/terminal_login/authorized_keys_command_url", description: "URL to the authorized_keys web service"
attribute "conjur/terminal_login/ssl_certificate", description: "SSL certificate of the terminal login LDAP server"
