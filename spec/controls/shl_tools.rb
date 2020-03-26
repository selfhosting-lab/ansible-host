# Task file for tests
ref_file = 'tasks/shl-tools.yml'

control 'shl-tools-01' do
  title 'Ensure SHL script library is installed'
  impact 'low'
  ref ref_file
  describe file('/usr/local/lib/shl.sh') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    unless virtualization.system == 'docker'
      its('selinux_label') { should eq 'system_u:object_r:lib_t:s0' }
    end
  end
end

control 'shl-tools-02' do
  title 'Ensure shl-reboot is installed'
  impact 'low'
  ref ref_file
  describe file('/usr/local/sbin/shl-reboot') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
    unless virtualization.system == 'docker'
      its('selinux_label') { should eq 'system_u:object_r:bin_t:s0' }
    end
  end
  describe command('shl-reboot') do
    it { should exist }
  end
end

control 'shl-tools-03' do
  title 'Ensure shl-reload is installed'
  impact 'low'
  ref ref_file
  describe file('/usr/local/sbin/shl-reload') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
    unless virtualization.system == 'docker'
      its('selinux_label') { should eq 'system_u:object_r:bin_t:s0' }
    end
  end
  describe command('shl-reload') do
    it { should exist }
  end
end
