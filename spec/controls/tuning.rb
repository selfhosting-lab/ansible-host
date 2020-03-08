# Task file for tests
ref_file = 'tasks/tuning.yml'

control 'tuning-01' do
  title 'Ensure the system will restart if the kernel panics'
  impact 'high'
  ref ref_file
  describe kernel_parameter('kernel.panic') do
    its('value') { should eq 10 }
  end
end

control 'tuning-02' do
  title 'Ensure the tuned packages are installed'
  impact 'medium'
  ref ref_file
  packages = %w[tuned-utils tuned-profiles-atomic]
  packages.each do |rpm|
    describe package(rpm) do
      it { should be_installed }
    end
  end
end

control 'tuning-03' do
  title 'Ensure tuned daemon is running'
  impact 'medium'
  ref ref_file
  describe systemd_service('tuned') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'tuning-04' do
  title 'Ensure correct tuned profile is active'
  impact 'medium'
  ref ref_file
  tuned_profile = 'atomic-guest'
  describe command('tuned-adm active') do
    its('stdout') { should cmp "Current active profile: #{tuned_profile}\n" }
  end
end
