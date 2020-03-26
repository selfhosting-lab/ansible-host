# Task file for tests
ref_file = 'tasks/admin.yml'

control 'admin-01' do
  title 'Ensure admin group exists'
  impact 'medium'
  ref ref_file
  describe group('admin') do
    it { should exist }
  end
end

control 'admin-02' do
  title 'Ensure admin group is in sudoers'
  impact 'medium'
  ref ref_file
  describe file('/etc/sudoers.d/admin') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0440' }
    unless virtualization.system == 'docker'
      its('selinux_label') { should eq 'system_u:object_r:etc_t:s0' }
    end
  end
end
