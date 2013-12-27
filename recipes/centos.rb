%w(nscd openldap openldap-clients nss-pam-ldapd authconfig).each do |pkg|
  package pkg do
    options '-y'
  end
end

# CentOS requires this, apparently
group "nslcd" do
  gid 3333
end

%w(nscd nslcd).each do |svc|
  service svc do
    supports :restart => true
  end
end

execute "authconfig" do
  command "authconfig --enablecache --enableldap --enableldapauth --enablemkhomedir --updateall"
  %w(nscd nslcd).each{ |s| notifies :restart, "service[#{s}]" }
end