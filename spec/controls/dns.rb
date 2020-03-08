# Task file for tests
ref_file = 'tasks/dns.yml'

control 'dns-01' do
  title 'Ensure NetworkManager is not managing DNS resolution'
  impact 'medium'
  ref ref_file
  only_if('DNS is not being managed by Ansible') { file('/etc/resolv.conf').content.match?(/# Managed by Ansible/) }
  describe file('/etc/NetworkManager/NetworkManager.conf') do
    its('content') { should match 'dns = none' }
  end
end

control 'dns-02' do
  title 'Ensure DNS resolution is configured'
  impact 'high'
  ref ref_file
  describe file('/etc/resolv.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('selinux_label') { should eq 'system_u:object_r:net_conf_t:s0' }
    its('content') { should match(/^nameserver +\S+/) }
  end
end

control 'dns-03' do
  title 'All defined nameservers should be reachable'
  impact 'critical'
  file('/etc/resolv.conf').content.scan(/^nameserver +(\S+)/) do |ns|
    describe host(ns[0], port: 53, protocol: 'udp') do
      it { should be_reachable }
    end
  end
end

control 'dns-04' do
  title 'GitHub should be resolvable'
  impact 'critical'
  describe host('github.com') do
    it { should be_resolvable }
  end
end
