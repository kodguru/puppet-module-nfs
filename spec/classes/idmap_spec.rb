require 'spec_helper'
require 'spec_functions'

describe 'nfs::idmap' do
  on_supported_os.sort.each do |os, facts|
    # these function calls mimic the hiera data, they are sourced in from spec/spec_functions.rb
    idmap_package         = idmap_package(facts)
    idmapd_service_name   = idmapd_service_name(facts)
    idmapd_service_ensure = idmapd_service_ensure(facts)

    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values for parameters' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_package(idmap_package).only_with_ensure('present') }

        it do
          is_expected.to contain_file('idmapd_conf').with(
            {
              'ensure'  => 'file',
              'path'    => '/etc/idmapd.conf',
              'content' => File.read(fixtures("idmapd_conf.#{facts[:os]['family']}")),
              'owner'   => 'root',
              'group'   => 'root',
              'require' => "Package[#{idmap_package}]",
            },
          )
        end

        if idmapd_service_name.nil?
          it { is_expected.not_to contain_service('idmapd_service') }
        else
          it do
            is_expected.to contain_service('idmapd_service').only_with(
              {
                'ensure'     => idmapd_service_ensure,
                'name'       => idmapd_service_name,
                'enable'     => true,
                'hasstatus'  => true,
                'hasrestart' => true,
                'subscribe'  => 'File[idmapd_conf]',
              },
            )
          end
        end
      end

      context 'with idmap_package set to valid value' do
        let(:params) { { idmap_package: 'testing' } }

        it { is_expected.to contain_package('testing').only_with_ensure('present') }
      end

      context 'with idmapd_conf_path set to valid value' do
        let(:params) { { idmapd_conf_path: '/test/ing' } }

        it { is_expected.to contain_file('idmapd_conf').with_path('/test/ing') }
      end

      context 'with idmapd_conf_owner set to valid value' do
        let(:params) { { idmapd_conf_owner: 'testing' } }

        it { is_expected.to contain_file('idmapd_conf').with_owner('testing') }
      end

      context 'with idmapd_conf_group set to valid value' do
        let(:params) { { idmapd_conf_group: 'testing' } }

        it { is_expected.to contain_file('idmapd_conf').with_group('testing') }
      end

      context 'with idmapd_conf_mode set to valid value' do
        let(:params) { { idmapd_conf_mode: '0242' } }

        it { is_expected.to contain_file('idmapd_conf').with_mode('0242') }
      end

      context 'with idmapd_service_name set to valid value' do
        let(:params) { { idmapd_service_name: 'testing' } }

        it { is_expected.to contain_service('idmapd_service').with_name('testing') }
      end

      context 'with idmapd_service_ensure set to valid value when idmapd_service_name is set' do
        let(:params) { { idmapd_service_ensure: 'running', idmapd_service_name: 'dummy' } }

        it { is_expected.to contain_service('idmapd_service').with_ensure('running') }
      end

      context 'with idmapd_service_enable set to valid value when idmapd_service_name is set' do
        let(:params) { { idmapd_service_enable: false, idmapd_service_name: 'dummy' } }

        it { is_expected.to contain_service('idmapd_service').with_enable(false) }
      end

      context 'with idmapd_service_hasstatus set to valid value when idmapd_service_name is set' do
        let(:params) { { idmapd_service_hasstatus: false, idmapd_service_name: 'dummy' } }

        it { is_expected.to contain_service('idmapd_service').with_hasstatus(false) }
      end

      context 'with idmapd_service_hasrestart set to valid value when idmapd_service_name is set' do
        let(:params) { { idmapd_service_hasrestart: false, idmapd_service_name: 'dummy' } }

        it { is_expected.to contain_service('idmapd_service').with_hasrestart(false) }
      end

      context 'with idmap_domain set to valid value' do
        let(:params) { { idmap_domain: 'test.ing' } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Domain = test.ing}) }
      end

      context 'with ldap_server set to valid value' do
        let(:params) { { ldap_server: 'test.ing' } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{LDAP_server = test.ing}) }
      end

      context 'with ldap_base set to valid value' do
        let(:params) { { ldap_base: ['testing'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{LDAP_base = testing}) }
      end

      context 'with ldap_base set to valid values' do
        let(:params) { { ldap_base: ['test', 'ing'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{LDAP_base = test,ing}) }
      end

      context 'with local_realms set to valid value' do
        let(:params) { { local_realms: ['test.ing'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{#Local-Realms = TEST.ING}) }
      end

      context 'with local_realms set to valid values' do
        let(:params) { { local_realms: ['first.dom', 'second.dom'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{#Local-Realms = FIRST.DOM,SECOND.DOM}) }
      end

      context 'with translation_method set to valid value' do
        let(:params) { { translation_method: ['static'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Method = static}) }
      end

      context 'with translation_method set to valid value' do
        let(:params) { { translation_method: ['static', 'umich_ldap'] } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Method = static,umich_ldap}) }
      end

      context 'with nobody_user set to valid value' do
        let(:params) { { nobody_user: 'testing' } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Nobody-User = testing}) }
      end

      context 'with nobody_group set to valid value' do
        let(:params) { { nobody_group: 'testing' } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Nobody-Group = testing}) }
      end

      context 'with verbosity set to valid value' do
        let(:params) { { verbosity: 242 } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Verbosity = 242}) }
      end

      context 'with pipefs_directory set to valid value' do
        let(:params) { { pipefs_directory: '/test/ing' } }

        it { is_expected.to contain_file('idmapd_conf').with_content(%r{Pipefs-Directory = /test/ing}) }
      end
    end
  end
end
