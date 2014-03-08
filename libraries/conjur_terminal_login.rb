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
    
    def stack
      conjur_conf['stack'] || 'v4'
    end
    
    def ldap_url(node)
      if result = node['conjur']['configuration']['ldap_url']
        result
      elsif appliance_url
        "ldaps://#{URI.parse(appliance_url).host}"
      else
        case stack
        when 'ci'
          'ldap://ldap-server-1050080273.us-east-1.elb.amazonaws.com:1389'
        else
          'ldap://ldap.conjur.ws:1389'
        end
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
