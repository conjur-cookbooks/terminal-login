require 'yaml'

## install package

apt_repository 'conjur' do
  uri 'http://apt.conjur.s3-website-us-east-1.amazonaws.com'
  components %w(universe multiverse)
  distribution node['lsb']['codename']
  # TODO: disable 'trusted' and provide explicit auth key information
  trusted true
  #keyserver "..."
  #key "..."
end

package 'logshipper'

## create the group, user, fifo and logfile

group "conjur"

user "logshipper" do
  system true
  shell '/bin/false'
  group "conjur"
end

fifo_path = node.conjur.logshipper.fifo_path

bash "mkfifo #{fifo_path}" do
  not_if { begin
    s = File.stat(fifo_path)
    [
      s.pipe?,
      (s.mode & 0777 == 0420),
      Etc.getpwuid(s.uid).name == 'logshipper',
      Etc.getgrgid(s.gid).name == 'syslog'
    ].all?
  rescue Errno::ENOENT
    false
  end }

  code """
    rm -f #{fifo_path}
    mkfifo --mode=0420 #{fifo_path}
    chown logshipper:syslog #{fifo_path}
  """
end

file "/var/log/logshipper.log" do
  owner 'logshipper'
end

## conjur identity

file "/etc/conjur.identity" do
  mode 0640
  group "conjur"
  # the details used here come from lib/conjur_terminal_login.rb

  # the regex is to pick just the hostname
  content """
    machine #{appliance_url[%r(^(?:.*//)?([^/]*)/?),1]}
    login host/#{host_id}
    password #{host_api_key}
  """
  notifies :restart, 'service[logshipper]', :delayed
end

## upstart unit

service 'logshipper' do
  provider Chef::Provider::Service::Upstart
end

file '/etc/init/logshipper.conf' do
  content %Q(
    description "Conjur log shipping agent"

    start on starting rsyslog
    stop on stopped rsyslog

    respawn

    setuid logshipper
    setgid conjur

    # workaround a bug in logshipper 0.1.0
    env HOME=/etc

    # don't route the messages through syslog to avoid loops
    exec /usr/sbin/logshipper -n #{fifo_path} >> /var/log/logshipper.log 2>&1
  )
  notifies :restart, 'service[logshipper]', :delayed
end

## rsyslog configuration

service 'rsyslog' do
  provider Chef::Provider::Service::Upstart
end

file '/etc/rsyslog.d/94-logshipper.conf' do
  content "auth,authpriv.* |#{fifo_path};RSYSLOG_SyslogProtocol23Format\n"
  notifies :restart, 'service[rsyslog]'
end
