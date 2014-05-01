require 'spec_helper'
require 'chef'
require "#{File.dirname(File.dirname(__FILE__))}/libraries/conjur_terminal_login"

describe ConjurTerminalLogin do
  describe "#cacertfile" do
    before {
      File.stub(:exists?).and_call_original
    }
    it "obtains from Chef attributes" do
      subject.cacertfile({
        'conjur' => {
          'ssl_certificate' => 'the-cert'
        }
      }) == "/opt/conjur/embedded/ssl/certs/conjur.pem"
    end
    it "obtains from /opt/conjur" do
      File.stub(:exists?).with("/opt/conjur/embedded/ssl/certs/conjur.pem").and_return true
      subject.cacertfile({}) == "/opt/conjur/embedded/ssl/certs/conjur.pem"
    end
    it "obtains from /etc/conjur.conf" do
      File.stub(:exists?).with("/opt/conjur/embedded/ssl/certs/conjur.pem").and_return false
      subject.stub(:conjur_conf).and_return({ cert_path: 'conjur.pem' })
      subject.cacertfile({}) == "/etc/conjur.pem"
    end
  end
  describe "host identity" do
    let(:node) { Chef::Node.new }
    subject { 
      Chef::Resource.new("stub").tap do |resource|
        resource.stub(:node).and_return node
      end
    }
    context "from attributes" do
      before {
        node.default.conjur.host_identity.id = 'the-host-id'
        node.default.conjur.host_identity.api_key = 'the-host-api-key'
      }
      its(:host_id) { should == 'the-host-id' }
      its(:host_api_key) { should == 'the-host-api-key' }
    end
    context "from netrc" do
      before {
        require 'ostruct'
        
        File.stub(:stat).and_call_original
        File.stub(:read).and_call_original
        File.stub(:stat).with("/root/.netrc").and_return OpenStruct.new(mode: 0600)
        File.stub(:read).with("/root/.netrc").and_return <<NETRC
machine https://conjur.example.com/api/authn
  login host/the-host
  password the-password
NETRC
        File.stub(:read).with("/etc/conjur.conf").and_return <<CONJUR_CONF
appliance_url: https://conjur.example.com/api
CONJUR_CONF
      }
      its(:host_id) { should == 'the-host' }
      its(:host_api_key) { should == 'the-password' }
    end
  end
end