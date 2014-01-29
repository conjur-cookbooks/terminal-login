module ConjurTerminalLogin
  class << self  
    def authorized_keys_command_url(node)
      if appliance_url
        authorized_keys_command_url = [ appliance_url, "pubkeys" ].join('/')
      else
        "https://pubkeys-#{account}-conjur.herokuapp.com"
      end
    end
    
    def account
      conjur_conf['account']
    end
    
    def ldap_url(node)
      if appliance_url
        ldap_url = "ldaps://#{URI.parse(appliance_url).host}"
      else
        node.conjur.terminal_login.ldap_url
      end
    end
    
    protected
    
    def conjur_conf
      require 'yaml'
      YAML.load(File.read("/etc/conjur.conf"))
    end
    
    def appliance_url
      conjur_conf['appliance_url']
    end
  end
end
