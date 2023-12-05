require 'spec_helper'
describe 'nfs::idmap' do
  supported_platforms = {
    'el6' => {
      osfamily:              'RedHat',
      release:               '6',
      idmapd_service_ensure: 'running',
      idmap_package:         'nfs-utils-lib',
      idmap_service_name:    'rpcidmapd',
      pipefs_directory:      nil,
    },
    'el7' => {
      osfamily:              'RedHat',
      release:               '7',
      idmapd_service_ensure: 'stopped',
      idmap_package:         'libnfsidmap',
      idmap_service_name:    'nfs-idmap',
      pipefs_directory:      nil,
    },
    'el8' => {
      osfamily:              'RedHat',
      release:               '8',
      idmapd_service_ensure: 'stopped',
      idmap_package:         'libnfsidmap',
      idmap_service_name:    'nfs-idmapd',
      pipefs_directory:      nil,
    },
    'el9' => {
      osfamily:              'RedHat',
      release:               '9',
      idmapd_service_ensure: 'stopped',
      idmap_package:         'libnfsidmap',
      idmap_service_name:    'nfs-idmapd',
      pipefs_directory:      nil,
    },
    'suse' => {
      osfamily:              'Suse',
      release:               '12',
      idmapd_service_ensure: nil,
      idmap_package:         'nfsidmap',
      idmap_service_name:    nil,
      pipefs_directory:      '/var/lib/nfs/rpc_pipefs',
    },
  }

  supported_platforms.sort.each do |_k, v|
    describe "on osfamily <#{v[:osfamily]}> when operatingsystemmajrelease is <#{v[:release]}>" do
      let :facts do
        {
          os: {
            family:      v[:osfamily],
            release: {
              major:     v[:release],
            },
          },
          kernelrelease: v[:kernelrelease],
        }
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_package(v[:idmap_package]).with_ensure('present') }

      it do
        is_expected.to contain_file('idmapd_conf').with(
          {
            'ensure'  => 'file',
            'path'    => '/etc/idmapd.conf',
            'content' => File.read(fixtures("idmapd_conf.#{v[:osfamily]}")),
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0644',
            'require' => "Package[#{v[:idmap_package]}]",
          },
        )
      end

      if v[:osfamily] == 'RedHat'
        it do
          is_expected.to contain_service('idmapd_service').with(
            {
              'ensure'     => v[:idmapd_service_ensure],
              'name'       => v[:idmap_service_name],
              'enable'     => true,
              'hasstatus'  => true,
              'hasrestart' => true,
              'subscribe'  => 'File[idmapd_conf]',
            },
          )
        end
      else
        it { is_expected.not_to contain_service('idmapd_service') }
      end
    end
  end

  context 'with idmap_package specified as valid string <test_package>' do
    let(:params) { { idmap_package: 'string' } }

    it { is_expected.to contain_package('string').with_ensure('present') }
    it { is_expected.to contain_file('idmapd_conf').with_require('Package[string]') }
  end

  context 'with idmapd_conf_path specified as valid string </test/idmapd.conf>' do
    let(:params) { { idmapd_conf_path: '/test/idmapd.conf' } }

    it { is_expected.to contain_file('idmapd_conf').with_path('/test/idmapd.conf') }
  end

  context 'with idmapd_conf_owner specified as valid string <test_owner>' do
    let(:params) { { idmapd_conf_owner: 'test_owner' } }

    it { is_expected.to contain_file('idmapd_conf').with_owner('test_owner') }
  end

  context 'with idmapd_conf_group specified as valid string <test_group>' do
    let(:params) { { idmapd_conf_group: 'test_group' } }

    it { is_expected.to contain_file('idmapd_conf').with_group('test_group') }
  end

  context 'with idmapd_conf_mode specified as valid string <0242>' do
    let(:params) { { idmapd_conf_mode: '0242' } }

    it { is_expected.to contain_file('idmapd_conf').with_mode('0242') }
  end

  # RedHat only service parameters
  ['RedHat', 'Suse'].each do |os|
    describe "on #{os}" do
      let :facts do
        {
          os: {
            family:  os,
            release: {
              major: '8', # only be used on RedHat
            },
          },
        }
      end

      context 'with idmapd_service_name specified as valid string <idmapd-test>' do
        let(:params) { { idmapd_service_name: 'idmapd-test' } }

        it { is_expected.to contain_service('idmapd_service').with_name('idmapd-test') }
      end

      context 'with idmapd_service_enable specified as valid boolean false' do
        let(:params) { { idmapd_service_enable: false } }

        if os == 'RedHat'
          it { is_expected.to contain_service('idmapd_service').with_enable(false) }
        else
          it { is_expected.not_to contain_service('idmapd_service') }
        end
      end

      context 'with idmapd_service_hasstatus specified as valid boolean false' do
        let(:params) { { idmapd_service_hasstatus: false } }

        if os == 'RedHat'
          it { is_expected.to contain_service('idmapd_service').with_hasstatus(false) }
        else
          it { is_expected.not_to contain_service('idmapd_service') }
        end
      end

      context 'with idmapd_service_hasrestart specified as valid boolean false' do
        let(:params) { { idmapd_service_hasrestart: false } }

        if os == 'RedHat'
          it { is_expected.to contain_service('idmapd_service').with_hasrestart('false') }
        else
          it { is_expected.not_to contain_service('idmapd_service') }
        end
      end
    end
  end

  context 'with idmap_domain specified as valid string <idmapd.testing.local>' do
    let(:params) { { idmap_domain: 'idmapd.testing.local' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Domain = idmapd.testing.local$}) }
  end

  context 'with ldap_server specified as valid string <ldap.testing.local>' do
    let(:params) { { ldap_server: 'ldap.testing.local' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^LDAP_server = ldap.testing.local$}) }
  end

  context 'with ldap_base specified as valid string <dc=local,dc=testing>' do
    let(:params) { { ldap_base: 'dc=local,dc=testing' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^LDAP_base = dc=local,dc=testing$}) }
  end

  context 'with ldap_base specified as valid array [<dc=local,dc=test1>, <dc=local,dc=test2>]' do
    let(:params) { { ldap_base: ['dc=local,dc=test1', 'dc=local,dc=test2'] } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^LDAP_base = dc=local,dc=test1,dc=local,dc=test2$}) }
  end

  context 'with local_realms specified as valid string <realms.testing.local>' do
    let(:params) { { local_realms: 'realms.testing.local' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^#Local-Realms = REALMS.TESTING.LOCAL$}) }
  end

  context 'with local_realms specified as valid array [<realm1.test.local>, <realm2.test.local>]' do
    let(:params) { { local_realms: ['realm1.test.local', 'realm2.test.local'] } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^#Local-Realms = REALM1.TEST.LOCAL,REALM2.TEST.LOCAL$}) }
  end

  context 'with translation_method as valid string <umich_ldap>' do
    let(:params) { { translation_method: 'umich_ldap' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Method = umich_ldap$}) }
  end

  context 'with translation_method as valid array [<umich_ldap>, <static>]' do
    let(:params) { { translation_method: ['umich_ldap', 'static'] } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Method = umich_ldap,static$}) }
  end

  context 'with nobody_user as valid string <somebody>' do
    let(:params) { { nobody_user: 'somebody' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Nobody-User = somebody$}) }
  end

  context 'with nobody_group as valid string <somegroup>' do
    let(:params) { { nobody_group: 'somegroup' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Nobody-Group = somegroup$}) }
  end

  context 'with verbosity as valid integer <242>' do
    let(:params) { { verbosity: 242 } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Verbosity = 242$}) }
  end

  context 'with pipefs_directory as valid string </test/rpc_pipefs>' do
    let(:params) { { pipefs_directory: '/test/rpc_pipefs' } }

    it { is_expected.to contain_file('idmapd_conf').with_content(%r{^Pipefs-Directory = /test/rpc_pipefs$}) }
  end

  describe 'variable type and content validations' do
    mandatory_params = {} if mandatory_params.nil?

    validations = {
      'Stdlib::Absolutepath' => {
        name:    ['idmapd_conf_path', 'pipefs_directory'],
        valid:   ['/absolute/filepath', '/absolute/directory/'],
        invalid: ['../invalid', 3, 2.42, ['array'], { 'ha' => 'sh' }, true, false, nil],
        message: '(expects a match for Variant\[Stdlib::Windowspath|expects a Stdlib::Absolutepath = Variant)', # Puppet 4|5
      },
      'Nfs::Idmap::Translation_method' => {
        name:    ['translation_method'],
        valid:   ['nsswitch', 'umich_ldap', 'static'],
        invalid: ['string', { 'ha' => 'sh' }, 3, 2.42, true],
        message: 'Pattern\[/^\(nsswitch|umich_ldap|static\)$/\]',

      },
      'Boolean' => {
        name:    ['idmapd_service_enable', 'idmapd_service_hasstatus', 'idmapd_service_hasrestart'],
        valid:   [true, false],
        invalid: ['true', 'false', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: 'expects a Boolean value',
      },
      'Integer' => {
        name:    ['verbosity'],
        valid:   [3, 242],
        invalid: ['3', ['array'], { 'ha' => 'sh' }, 2.42, true, nil],
        message: 'expects an Integer value',
      },
      'Optional[String[1]]' => {
        name:    ['idmap_package', 'idmapd_service_name'],
        valid:   ['string', nil],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, ''],
        message: 'type Undef or String',
      },
      'String[1]' => {
        name:    ['idmapd_conf_owner', 'idmapd_conf_group', 'nobody_user', 'nobody_group'],
        valid:   ['string'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, ''],
        message: '(expects a String|expects a String\[1\])',
      },
      'Nfs::Idmap::Local_realms' => {
        name:    ['local_realms'],
        valid:   ['string', ['array']],
        invalid: [{ 'ha' => 'sh' }, 3, 2.42, true],
        message: 'Stdlib::Fqdn',
      },
      'Stdlib::Fqdn' => {
        name:    ['idmap_domain'],
        valid:   ['test.domain'],
        invalid: ['test,domain', ['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message: 'Pattern',
      },
      'Optional[Stdlib::Fqdn]' => {
        name:    ['ldap_server'],
        valid:   ['ldap.domain.tld', nil],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message: 'Pattern',
      },
      'Optional[Stdlib::Ensure::Service]' => {
        name:    ['idmapd_service_ensure'],
        valid:   ['stopped', 'running'],
        invalid: ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, 'true'],
        message: 'Enum\[\'running\', \'stopped\'\]',
      },
      'Stdlib::Filemode' => {
        name:    ['idmapd_conf_mode'],
        valid:   ['0777', '0644', '0242'],
        invalid: ['0999', ['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message: '[/^[0124]{1}[0-7]{3}$/]',
      },
      'undef/string/array' => {
        name:    ['ldap_base'],
        valid:   ['string', ['array']],
        invalid: [{ 'ha' => 'sh' }, 3, 2.42, true],
        message: 'expects a value of type Undef, String, or Array',
      },
    }

    validations.sort.each do |type, var|
      mandatory_params = {} if mandatory_params.nil?
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:facts) { [mandatory_facts, var[:facts]].reduce(:merge) } unless var[:facts].nil?
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": valid, }].reduce(:merge) }

            it { is_expected.to compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

            it 'fail' do
              expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
