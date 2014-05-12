require_relative 'spec_helper'

group = 'docker-registry'
install_dir = '/opt/docker-registry'
port_number = 5000
required_packages = %w(libevent-dev git libffi-dev liblzma-dev)
service_provider = 'supervisor'
service_name = 'docker-registry'
username = 'docker-registry'

describe user(username) do
  it { should exist }
end

describe group(group) do
  it { should exist }
end

describe file(install_dir) do
  it { should be_directory }
  it { should be_owned_by 'docker-registry' }
  it { should be_grouped_into 'docker-registry' }
end

required_packages.each do |pkg|
  describe package(pkg) do
    it { should be_installed }
  end
end

describe file("#{install_dir}/shared/config.yml") do
  it { should be_mode 440 }
  it { should be_owned_by username }
  it { should be_grouped_into group }
  it { should be_readable.by('owner') }
  it { should be_readable.by('group') }
  it { should_not be_readable.by('others') }
  it { should_not be_writable.by('owner') }
  it { should_not be_writable.by('group') }
  it { should_not be_writable.by('others') }
  [
    # Based on default attributes:
    'storage: local',
    'storage_path: /var/lib/docker-registry',
    'standalone: true',
    # Based on .kitchen.yml
    'secret_key: CHANGEME'
  ].each do |config_line|
    it do
      should contain(config_line).
      after(%r{^common:$}).
      before(%r{^dev:$})
    end
  end
end

describe file("#{install_dir}/current/config/config.yml") do
  it { should be_linked_to "#{install_dir}/shared/config.yml" }
end

describe service(service_provider) do
  it { should be_enabled }
  it { should be_running }
end

describe service(service_name) do
  it { should be_running.under(service_provider) }
end

# Based on default attributes:
describe port(port_number) do
  it { should be_listening }
end
