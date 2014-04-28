require 'chefspec'
require 'spec_helper'
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
    end
  }
  let(:subject) {
    chef_run.converge(described_recipe)
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
  
  context "without SSL certificate or appliance_url" do
    it "should use debian platform family" do
      subject.node.platform_family.should == "debian"
    end
    it "doesn't put the cert in openldap" do
      subject.should_not create_file("/etc/ldap/cacerts/conjur.pem")
    end
    it "creates /etc/ldap/ldap.conf" do
      subject.should create_template("/etc/ldap/ldap.conf").with(
        variables: {
          account: 'test',
          host_id: "the-host", 
          uri: "ldap://ec2-174-129-243-206.compute-1.amazonaws.com", 
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
          uri: "ldap://ec2-174-129-243-206.compute-1.amazonaws.com", 
          cacertfile: nil
        }
      )
    end
    it "creates conjur_authorized_keys" do
      subject.should create_template("/usr/local/bin/conjur_authorized_keys").with(
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
    it "creates /etc/ldap/ldap.conf" do
      subject.should create_template("/etc/ldap/ldap.conf").with(
        variables: {
          account: 'test',
          host_id: "the-host", 
          uri: "ldap://ec2-174-129-243-206.compute-1.amazonaws.com", 
          cacertfile: "/opt/conjur/embedded/ssl/certs/conjur.pem"
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
          uri: "ldap://ec2-174-129-243-206.compute-1.amazonaws.com", 
          cacertfile: "/opt/conjur/embedded/ssl/certs/conjur.pem"
        }
      )
    end
    it "creates conjur_authorized_keys" do
      subject.should create_template("/usr/local/bin/conjur_authorized_keys").with(
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
    it "creates /etc/ldap/ldap.conf" do
      subject.should create_template("/etc/ldap/ldap.conf").with(
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
    it "creates conjur_authorized_keys" do
      subject.should create_template("/usr/local/bin/conjur_authorized_keys").with(
        variables: {
          uri: "https://conjur/api/pubkeys", 
          options: ""
        }
      )
    end
  end
end