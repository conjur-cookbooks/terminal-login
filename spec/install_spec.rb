require 'chefspec'
require 'spec_helper'

describe "terminal-login::install" do
  let(:chef_run) {
    ChefSpec::Runner.new(platform: platform, version: version) 
  }
  let(:subject) {
    chef_run.converge(described_recipe)
  }
  before {
    File.stub(:read).and_call_original
    File.stub(:read).with('/etc/ssh/sshd_config').and_return ""
  }
  context "ubuntu platform" do
    let(:platform) { 'ubuntu' }
    let(:version) { '12.04' }
    before {
      chef_run.node.automatic.platform_family = 'debian'
    }
    it "executes successfully" do
      subject.should be_true
    end
    it "executes ubuntu scripts" do
      subject.should run_execute("pam-auth-update")
    end
  end
  context "centos platform" do
    let(:platform) { 'centos' }
    let(:version) { '6.2' }
    before {
      chef_run.node.automatic.platform_family = 'rhel'
    }
    it "executes successfully" do
      subject.should be_true
    end
    it "executes centos scripts" do
      subject.should run_execute("authconfig")
    end
  end
end
