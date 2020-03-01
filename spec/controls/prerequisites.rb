# Task file for tests
ref_file = 'tasks/prerequisites.yaml'

control 'prerequisites-01' do
  title 'Ensure prerequisite packages are installed'
  impact 'low'
  ref ref_file
  describe package('python3-libselinux') do
    it { should be_installed }
  end
end
