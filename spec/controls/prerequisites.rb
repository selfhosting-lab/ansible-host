# Task file for tests
ref_file = 'tasks/prerequisites.yml'

control 'prerequisites-01' do
  title 'Ensure prerequisite packages are installed'
  impact 'low'
  ref ref_file
  packages = %w[file kernel python3-libselinux]
  packages.each do |rpm|
    describe package(rpm) do
      it { should be_installed }
    end
  end
end
