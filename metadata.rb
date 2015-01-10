name              'terminal-login'
maintainer        'Conjur, Inc.'
maintainer_email  'kgilpin@conjur.net'
license           'Apache 2.0'
description       'Installs Conjur PAM+LDAP'
version           '0.2.3'

recipe "terminal-login::install", "Installs necessary packages and sets up essential configuration options for PAM and LDAP"
recipe "terminal-login::configure", "Configures PAM + LDAP to connect to Conjur as described in /etc/conjur.conf"
recipe "terminal-login::sudoers", "Gives passwordless sudo to conjurers"

depends "apt"
depends "sshd-service"
depends "conjur-client"
depends "yum"

%w(ubuntu centos fedora).each do |platform|
  supports platform
end
