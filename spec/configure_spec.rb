require 'chefspec'
require "#{File.dirname(File.dirname(__FILE__))}/libraries/conjur_terminal_login"

describe "terminal-login::configure" do
  let(:attributes) { 
    {
      'conjur' => {
        'host_identity' => {
          'id' => 'the-host',
          'api_key' => 'the-host-api-key'
        }
      }
    } 
  }
  let(:chef_run) {
    ChefSpec::Runner.new(platform: 'ubuntu', version: '12.04') do |node|
      attributes.each do |k,v|
        node.override[k] = v
      end
    end.converge(described_recipe) 
  }
  let(:conjur_conf) {
    YAML.dump({
      "account" => "test",
      "plugins" => %w(a b)
    })
  }
  before {
    File.stub(:read).and_call_original
    File.stub(:read).with("/etc/conjur.conf").and_return conjur_conf
    File.stub(:exists?).and_call_original
    File.stub(:exists?).with("/opt/conjur/embedded/ssl/certs/conjur.pem").and_return false
  }
  subject { chef_run }
  
  context "without SSL certificate or appliance_url" do
    it "doesn't put the cert in openldap" do
      subject.should_not create_file("/etc/openldap/cacerts/conjur.pem")
    end
    it "creates /etc/openldap/ldap.conf" do
      subject.should create_template("/etc/openldap/ldap.conf").with(
        variables: {
          account: 'test',
          host_id: "the-host", 
          uri: "ldap://ldap.conjur.ws:1389", 
          cacertfile: nil
        }
      )
    end
    it "creates /etc/nslcd.conf" do
      subject.should create_template("/etc/nslcd.conf").with(
        variables: {
          account: "test",
          host_id: "the-host", 
          host_api_key: "the-host-api-key",
          gid: "nslcd",
          uri: "ldap://ldap.conjur.ws:1389", 
          cacertfile: nil
        }
      )
    end
    it "creates /root/authorized_keys.sh" do
      subject.should create_template("/root/authorized_keys.sh").with(
        variables: {
          uri: "https://pubkeys-test-conjur.herokuapp.com", 
          options: ""
        }
      )
    end
  end
  context "with SSL certificate" do
    before {
      File.stub(:exists?).with("/opt/conjur/embedded/ssl/certs/conjur.pem").and_return true
      File.stub(:read).with("/opt/conjur/embedded/ssl/certs/conjur.pem").and_return "the-cert-content"
    }
    it "creates LDAP certfile" do
      subject.should create_file("/etc/openldap/cacerts/conjur.pem").with(
        content: "the-cert-content"
      )
    end
    it "creates /etc/openldap/ldap.conf" do
      subject.should create_template("/etc/openldap/ldap.conf").with(
        variables: {
          account: 'test',
          host_id: "the-host", 
          uri: "ldap://ldap.conjur.ws:1389", 
          cacertfile: "/etc/openldap/cacerts/conjur.pem"
        }
      )
    end
    it "creates /etc/nslcd.conf" do
      subject.should create_template("/etc/nslcd.conf").with(
        variables: {
          account: "test",
          host_id: "the-host", 
          host_api_key: "the-host-api-key",
          gid: "nslcd",
          uri: "ldap://ldap.conjur.ws:1389", 
          cacertfile: "/etc/openldap/cacerts/conjur.pem"
        }
      )
    end
    it "creates /root/authorized_keys.sh" do
      subject.should create_template("/root/authorized_keys.sh").with(
        variables: {
          uri: "https://pubkeys-test-conjur.herokuapp.com", 
          options: "--cacert /opt/conjur/embedded/ssl/certs/conjur.pem"
        }
      )
    end
  end
  context "with appliance_url" do
    let(:conjur_conf) {
      YAML.dump({
        "account" => "test",
        "appliance_url" => "https://conjur/api",
        "plugins" => %w(a b)
      })
    }
    it "creates /etc/openldap/ldap.conf" do
      subject.should create_template("/etc/openldap/ldap.conf").with(
        variables: {
          account: 'test',
          host_id: "the-host", 
          uri: "ldaps://conjur", 
          cacertfile: nil
        }
      )
    end
    it "creates /etc/nslcd.conf" do
      subject.should create_template("/etc/nslcd.conf").with(
        variables: {
          account: "test",
          host_id: "the-host", 
          host_api_key: "the-host-api-key",
          gid: "nslcd",
          uri: "ldaps://conjur", 
          cacertfile: nil
        }
      )
    end
    it "creates /root/authorized_keys.sh" do
      subject.should create_template("/root/authorized_keys.sh").with(
        variables: {
          uri: "https://conjur/api/pubkeys", 
          options: ""
        }
      )
    end
  end
end