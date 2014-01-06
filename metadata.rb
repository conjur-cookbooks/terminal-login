name              'terminal-login'
maintainer        'Conjur, Inc.'
maintainer_email  'kgilpin@conjur.net'
license           'Apache 2.0'
description       'Installs Conjur PAM+LDAP'
version           '0.1.0'

recipe "terminal-login::sudoers", "Gives passwordless sudo to conjurers"

depends "sshd-service"

%w(ubuntu centos fedora).each do |platform|
  supports platform
end
