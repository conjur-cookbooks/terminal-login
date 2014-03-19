# Cleanup before AMI build.
# Don't run in other environments as it deletes keys
# and cuts off ssh access to the VM.

directory "/root/.ssh" do
  action :delete
  recursive true
end

