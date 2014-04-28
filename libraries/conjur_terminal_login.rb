module ConjurTerminalLogin
  class << self
    def cacertfile(node)
      if node['conjur']['ssl_certificate'] || File.exists?("/opt/conjur/embedded/ssl/certs/conjur.pem")
        "/opt/conjur/embedded/ssl/certs/conjur.pem"
      else
        nil
      end
    end
    
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
          'ldap://ec2-54-83-52-194.compute-1.amazonaws.com'
        else
          'ldap://ec2-174-129-243-206.compute-1.amazonaws.com'
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

class Chef::Resource
  def conjur_account
    ConjurTerminalLogin.account
  end

  def authorized_keys_command_url
    ConjurTerminalLogin.authorized_keys_command_url(node)
  end

  def ldap_url
    ConjurTerminalLogin.ldap_url(node)
  end
  
  def cacertfile
    ConjurTerminalLogin.cacertfile(node)
  end
end
