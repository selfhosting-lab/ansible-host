# Task file for tests
ref_file = 'tasks/dnf.yaml'

control 'dnf-01' do
  title 'Set number of DNF download workers'
  impact 'low'
  ref ref_file
  describe file('/etc/dnf/dnf.conf') do
    its('content') { should match 'max_parallel_downloads = 10' }
  end
end

control 'dnf-02' do
  title 'Use fastest mirror'
  impact 'low'
  ref ref_file
  describe file('/etc/dnf/dnf.conf') do
    its('content') { should match 'fastestmirror = yes' }
  end
end

control 'dnf-03' do
  title 'Ensure DNF plugins are installed'
  impact 'high'
  ref ref_file
  packages = %w[
    dnf-automatic
    dnf-utils
    python3-dnf-plugin-leaves
    python3-dnf-plugin-show-leaves
    python3-dnf-plugin-system-upgrade
    python3-dnf-plugin-versionlock
  ]
  packages.each do |rpm|
    describe package(rpm) do
      it { should be_installed }
    end
  end
end

control 'dnf-04' do
  title 'Ensure automatic security updates are configured'
  impact 'high'
  ref ref_file
  describe file('/etc/dnf/automatic.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('selinux_label') { should eq 'system_u:object_r:etc_t:s0' }
    its('content') { should match 'download_updates = yes' }
    its('content') { should match 'apply_updates = yes' }
  end
end

control 'dnf-05' do
  title 'Ensure automatic security updates are enabled'
  impact 'high'
  ref ref_file
  describe systemd_service('dnf-automatic.timer') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'dnf-06' do
  title 'Ensure automatic refresh of DNF cache is enabled'
  impact 'low'
  ref ref_file
  describe systemd_service('dnf-makecache.timer') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'dnf-07' do
  title 'Ensure DNF uses only HTTPS mirrors'
  impact 'medium'
  ref ref_file
  repofiles = command('find /etc/yum.repos.d/*.repo -type f').stdout.split("\n").map(&:strip)
  repofiles.each do |repofile|
    describe "Repofile #{repofile}" do
      subject { file(repofile) }
      it 'should only contain https mirrorlists' do
        expect(subject.content).not_to match(/^metalink=(((?!&protocol=https)\S)+)$/)
      end
    end
  end
  describe command('dnf repoinfo') do
    its('stdout') { should_not match(/^Repo-metalink: (((?!&protocol=https)\S)+)$/) }
  end
end
