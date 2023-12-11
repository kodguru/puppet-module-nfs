require 'spec_helper'
require 'spec_functions'

describe 'nfs' do
  on_supported_os.sort.each do |os, facts|
    # these function calls mimic the hiera data, they are sourced in from spec/spec_functions.rb
    include_rpcbind    = include_rpcbind(facts)
    include_idmap      = include_idmap(facts)
    nfs_package        = nfs_package(facts)
    nfs_service        = nfs_service(facts)
    nfs_service_ensure = nfs_service_ensure(facts)
    nfs_service_enable = nfs_service_enable(facts)

    nfs_packages       = []

    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values for parameters' do
        it { is_expected.to compile.with_all_deps }

        if include_rpcbind == true
          it { is_expected.to contain_class('rpcbind') }
        else
          it { is_expected.not_to contain_class('rpcbind') }
        end

        if include_idmap == true
          it { is_expected.to contain_class('nfs::idmap') }
        else
          it { is_expected.not_to contain_class('nfs::idmap') }
        end

        nfs_package.each do |package|
          it { is_expected.to contain_package(package).with_ensure('present') }

          nfs_packages.push("Package[#{package}]") # prepare package list for service subscribe
        end

        if nfs_service.nil?
          it { is_expected.not_to contain_service('nfs_service') }
        else
          it do
            is_expected.to contain_service('nfs_service').only_with(
              {
                'ensure'     => nfs_service_ensure,
                'name'       => nfs_service,
                'enable'     => nfs_service_enable,
                'hasstatus'  => true,
                'hasrestart' => true,
                'require'    => nil,
                'subscribe'  => nfs_packages,
              },
            )
          end
        end
      end

      context 'with include_rpcbind set to valid true' do
        let(:params) { { include_rpcbind: true } }

        it { is_expected.to contain_class('rpcbind') }
      end

      context 'with include_rpcbind set to valid false' do
        let(:params) { { include_rpcbind: false } }

        it { is_expected.not_to contain_class('rpcbind') }
      end

      context 'with include_idmap set to valid true' do
        let(:params) { { include_idmap: true } }

        it { is_expected.to contain_class('nfs::idmap') }
      end

      context 'with include_idmap set to valid false' do
        let(:params) { { include_idmap: false } }

        it { is_expected.not_to contain_class('nfs::idmap') }
      end

      context 'with nfs_package set to valid array' do
        let(:params) { { nfs_package: ['test', 'ing'] } }

        it { is_expected.to contain_package('test') }
        it { is_expected.to contain_package('ing') }
      end

      context 'with nfs_package set to valid array when nfs_service is set' do
        let(:params) { { nfs_package: ['test', 'ing'], nfs_service: 'dummy' } }

        it { is_expected.to contain_service('nfs_service').with_subscribe(['Package[test]', 'Package[ing]']) }
      end

      context 'with nfs_service set to valid value' do
        let(:params) { { nfs_service: 'testing' } }

        it { is_expected.to contain_service('nfs_service').with_name('testing') }
      end

      context 'with nfs_service_ensure set to valid value when nfs_service is set' do
        let(:params) { { nfs_service_ensure: 'running', nfs_service: 'dummy' } }

        it { is_expected.to contain_service('nfs_service').with_ensure('running') }
      end

      context 'with nfs_service_enable set to valid true when nfs_service is set' do
        let(:params) { { nfs_service_enable: true, nfs_service: 'dummy' } }

        it { is_expected.to contain_service('nfs_service').with_enable(true) }
      end

      context 'with mounts set to valid hash when hiera_hash is false' do
        let(:params) do
          {
            mounts: {
              '/first/test' => {
                'ensure' => 'present',
                'fstype' => 'nfs',
                'device' => 'test:/first/test',
              },
              '/second/test' => {
                'ensure' => 'present',
                'fstype' => 'nfs',
                'device' => 'test:/second/test',
              },
            },
            hiera_hash: false,
          }
        end

        it { is_expected.to have_types__mount_resource_count(2) }
        it do
          is_expected.to contain_types__mount('/first/test').with(
            {
              'ensure' => 'present',
              'fstype' => 'nfs',
              'device' => 'test:/first/test',
            },
          )
        end

        it do
          is_expected.to contain_types__mount('/second/test').with(
            {
              'ensure' => 'present',
              'fstype' => 'nfs',
              'device' => 'test:/second/test',
            },
          )
        end
      end

      context 'with server set to valid true when nfs_service is true' do
        let(:params) { { server: true, nfs_service: 'dummy' } }

        if facts[:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_file('nfs_exports').only_with(
              {
                'ensure' => 'file',
                'path'   => '/etc/exports',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
                'notify' => 'Exec[update_nfs_exports]',
              },
            )
          end

          it do
            is_expected.to contain_exec('update_nfs_exports').only_with(
              {
                'command'     => 'exportfs -ra',
                'path'        => '/bin:/usr/bin:/sbin:/usr/sbin',
                'refreshonly' => true,
              },
            )
          end

          it { is_expected.to contain_service('nfs_service').with_subscribe(nfs_packages) }
        else
          it 'fail' do
            expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{This platform is not configured to be an NFS server})
          end
        end
      end

      context 'with exports_path set to valid value when server is true' do
        let(:params) { { exports_path: '/test/ing', server: true } }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('nfs_exports').with_path('/test/ing') }
        else
          it 'fail' do
            expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{This platform is not configured to be an NFS server})
          end
        end
      end

      context 'with exports_owner set to valid value when server is true' do
        let(:params) { { exports_owner: 'testing', server: true } }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('nfs_exports').with_owner('testing') }
        else
          it 'fail' do
            expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{This platform is not configured to be an NFS server})
          end
        end
      end

      context 'with exports_group set to valid value when server is true' do
        let(:params) { { exports_group: 'testing', server: true } }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('nfs_exports').with_group('testing') }
        else
          it 'fail' do
            expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{This platform is not configured to be an NFS server})
          end
        end
      end

      context 'with exports_mode set to valid value when server is true' do
        let(:params) { { exports_mode: '0242', server: true } }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('nfs_exports').with_mode('0242') }
        else
          it 'fail' do
            expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{This platform is not configured to be an NFS server})
          end
        end
      end
    end
  end
end
