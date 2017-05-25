require 'spec_helper'

PROVIDERS = ["undef", "'debian'"]
SERVICES = ["dep8-sd-only", "dep8-sd-sysv", "dep8-sysv-only"]

def set_service(service, running, enable, provider)
  command("puppet apply --debug --detailed-exitcodes -e \"service { '#{service}' : ensure => #{running}, enable => #{enable}, provider => #{provider} }\"")
end

describe file("/run/systemd/system") do
  it { should be_directory }
end

PROVIDERS.each do |provider|
  SERVICES.each do |service|
    describe set_service(service, "running", "true", provider) do
      its(:stdout) { should match /systemctl enable/ }
      its(:stdout) { should match /(systemctl|service).* start/ }
      its(:exit_status) { should eq 2 }
    end

    # The second run should be noop
    describe set_service(service, "running", "true", provider) do
      its(:exit_status) { should eq 0 }
    end

    describe file("/tmp/#{service}.status") do
      it { should be_file }
    end

    describe set_service(service, "stopped", "false", provider) do
      its(:stdout) { should match /systemctl disable/ }
      its(:stdout) { should match /(systemctl|service).* stop/ }
      its(:exit_status) { should eq 2 }
    end

    # The second run should be noop
    describe set_service(service, "stopped", "false", provider) do
      its(:exit_status) { should eq 0 }
    end

    describe file("/tmp/#{service}.status") do
      it { should_not be_file }
    end

  end
end
