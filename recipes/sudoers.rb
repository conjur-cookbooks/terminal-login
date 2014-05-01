template "/etc/sudoers.d/conjurers" do
  source "sudoers.d_conjurers.erb"
  mode 0440
end

