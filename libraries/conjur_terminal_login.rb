module ConjurTerminalLogin
  class << self
    def cacertfile(node)
      if (node['conjur'] && node['conjur']['ssl_certificate']) || File.exists?("/opt/conjur/embedded/ssl/certs/conjur.pem")
        "/opt/conjur/embedded/ssl/certs/conjur.pem"
      elsif cert_file = conjur_conf['cert_file']
        File.expand_path(cert_file, "/etc/")
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
    
    def host_id(node)
      begin
        node.conjur.host_identity.id
      rescue NoMethodError
        id = netrc[0] or raise "No host identity found in attributes or netrc"
        tokens = id.split('/')
        raise "Expecting host id in netrc" unless tokens[0] == 'host'
        tokens[1..-1].join('/')
      end
    end
    
    def host_api_key(node)
      begin
        node.conjur.host_identity.api_key
      rescue NoMethodError
        netrc[1] or raise "No host api key found in attributes or netrc"
      end
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
    
    def netrc
      require 'netrc'
      netrc = Netrc.read('/root/.netrc')
      netrc["#{appliance_url}/authn"] || []
    end
    
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
  
  def host_id
    ConjurTerminalLogin.host_id(node)
  end

  def host_api_key
    ConjurTerminalLogin.host_api_key(node)
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
