%w(nscd openldap openldap-clients nss-pam-ldapd authconfig).each do |pkg|
  package pkg do
    options '-y'
  end
end

execute "authconfig" do
  command "authconfig --enablecache --enableldap --enableldapauth --enablemkhomedir --updateall"
  notifies :restart, "service[nslcd]"
end