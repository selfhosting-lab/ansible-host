# Task file for tests
ref_file = 'tasks/swap.yaml'

control 'swap-01' do
  title 'Ensure swapfile exists and has appropriate permissions'
  impact 'medium'
  ref ref_file
  only_if('Swap is not being managed') { file('/var/cache/swap').exist? }
  describe file('/var/cache/swap') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
    its('selinux_label') { should eq 'system_u:object_r:swapfile_t:s0' }
  end
end

control 'swap-02' do
  title 'Ensure swapfile is formatted correctly'
  impact 'medium'
  ref ref_file
  only_if('Swap is not being managed') { file('/var/cache/swap').exist? }
  describe command('file /var/cache/swap') do
    its('stdout') { should match 'swap file' }
  end
end

control 'swap-03' do
  title 'Ensure swapfile is in fstab'
  ref 'roles/system/tasks/swap.yaml'
  impact 'medium'
  only_if('Swap is not being managed') { file('/var/cache/swap').exist? }
  describe(etc_fstab.where { device_name == '/var/cache/swap' }) do
    its('file_system_type') { should cmp 'swap' }
  end
end

control 'swap-04' do
  title 'Ensure swapfile is enabled'
  impact 'medium'
  ref ref_file
  only_if('Swap is not being managed') { file('/var/cache/swap').exist? }
  describe command('swapon -s') do
    its('stdout') { should match '/var/cache/swap' }
  end
end
