require 'yaml'

## install package

case node.platform_family
when 'debian'
  apt_repository 'conjur' do
    uri 'http://apt.conjur.s3-website-us-east-1.amazonaws.com'
    components %w(main)
    distribution node['lsb']['codename']
    key "apt.key"
  end
when 'rhel'
  cookbook_file '/etc/pki/rpm-gpg/RPM-GPG-KEY-Conjur' do
    mode '644'
    source 'apt.key'
  end

  yum_repository 'conjur' do
    description 'Conjur Inc.'
    baseurl 'http://yum.conjur.s3-website-us-east-1.amazonaws.com'
    gpgkey 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Conjur'
  end
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
if node.etc.group.include? 'syslog'
  fifo_group = 'syslog'
else
  fifo_group = 'root'
end

bash "mkfifo #{fifo_path}" do
  not_if { begin
    s = File.stat(fifo_path)
    [
      s.pipe?,
      (s.mode & 0777 == 0460),
      s.uid == node.etc.passwd.logshipper.uid,
      s.gid == node.etc.group[fifo_group].gid,
    ].all?
  rescue Errno::ENOENT, NoMethodError
    false
  end }

  code """
    rm -f #{fifo_path}
    mkfifo --mode=0460 #{fifo_path}
    chown logshipper:#{fifo_group} #{fifo_path}
  """

  # we need to restart as the pipe has moved
  notifies :restart, 'service[logshipper]', :delayed
  notifies :restart, 'service[rsyslog]', :delayed
end

file "/var/log/logshipper.log" do
  owner 'logshipper'
  mode '0640'
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

# differentiate here the platform-specific parts

# generic (tested on ubuntu)
upstart_script = %Q(
  start on starting rsyslog
  stop on stopped rsyslog

  setuid logshipper
  setgid conjur

  exec /usr/sbin/logshipper -n #{fifo_path} >> /var/log/logshipper.log 2>&1
)

# workarounds
case node.platform
when 'centos'
  upstart_script = %Q(
    # rsyslog isn't upstarted here
    start on (local-filesystems and net-device-up IFACE!=lo)
    stop on runlevel [016]

    # old upstart, no set[ug]id stanzas
    exec runuser -s /bin/bash logshipper -g conjur -- -c /usr/sbin/logshipper -n #{fifo_path} >> /var/log/logshipper.log 2>&1
  )
end

file '/etc/init/logshipper.conf' do
  content %Q(
    description "Conjur log shipping agent"

    respawn

    # workaround a bug in logshipper 0.1.0
    env HOME=/etc
  ) + upstart_script

  notifies :restart, 'service[logshipper]', :delayed
end

## rsyslog configuration

service 'rsyslog' do
  provider Chef::Provider::Service::Upstart if node.platform == 'ubuntu'
end

file '/etc/rsyslog.d/94-logshipper.conf' do
  content "auth,authpriv.* |#{fifo_path};RSYSLOG_SyslogProtocol23Format\n"
  notifies :restart, 'service[rsyslog]'
end
