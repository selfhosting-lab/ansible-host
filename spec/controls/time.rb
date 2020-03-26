# Task file for tests
ref_file = 'tasks/time.yml'

control 'time-01' do
  title 'Ensure a timezone is set'
  impact 'medium'
  ref ref_file
  describe file('/etc/localtime') do
    its('link_path') { should match '/usr/share/zoneinfo/*' }
  end
end

control 'time-02' do
  title 'Ensure chronyd package is installed'
  impact 'medium'
  ref ref_file
  describe package('chrony') do
    it { should be_installed }
  end
end

control 'time-03' do
  title 'Ensure chronyd uses socket instead of IP'
  impact 'medium'
  ref ref_file
  only_if('Running in a Docker container') { virtualization.system != 'docker' }
  describe file('/etc/chrony.conf') do
    its('content') { should match(/^cmdport 0/) }
  end
  describe port(323) do
    it { should_not be_listening }
  end
  describe file('/var/run/chrony/chronyd.sock') do
    it { should exist }
    its('type') { should eq :socket }
  end
end

control 'time-04' do
  title 'Ensure a time pool is set'
  impact 'medium'
  ref ref_file
  describe file('/etc/chrony.conf') do
    its('content') { should match(/^pool \S+ iburst/) }
  end
end

control 'time-05' do
  title 'Ensure time synchronisation is running'
  impact 'medium'
  ref ref_file
  only_if('Running in a Docker container') { virtualization.system != 'docker' }
  describe systemd_service('chronyd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
  describe command('chronyc serverstats') do
    its('exit_status') { should eq 0 }
  end
end

control 'time-06' do
  title 'Ensure time servers can be reached'
  impact 'medium'
  file('/etc/chrony.conf').content.scan(/^pool +(.*) iburst/) do |pool|
    describe host(pool[0], port: 123, protocol: 'udp') do
      it { should be_resolvable }
      it { should be_reachable }
    end
  end
  unless virtualization.system == 'docker'
    describe command('chronyc activity') do
      its('stdout') { should match(/^[1-9]\d* sources online/) }
    end
  end
end

control 'time-07' do
  title 'Ensure time is synchronised within 5 seconds'
  impact 'low'
  only_if('Running in a Docker container') { virtualization.system != 'docker' }
  describe command('chronyc tracking') do
    its('stdout') { should match(/^System time *: -?[0-4](\.\d+)?/) }
  end
end
