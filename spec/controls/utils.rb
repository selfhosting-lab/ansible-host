# Task file for tests
ref_file = 'tasks/utils.yml'

control 'utils-01' do
  title 'Ensure utility packages are installed'
  impact 'low'
  ref ref_file
  packages = %w[
    bash-completion bind-utils curl git htop httpd-tools iotop iperf3 jq 
    kexec-tools lsof nfs-utils nmap-ncat perf pv realmd socat stress-ng tcpdump
    tmux vim-enhanced wget
  ]
  packages.each do |rpm|
    describe package(rpm) do
      it { should be_installed }
    end
  end
end
