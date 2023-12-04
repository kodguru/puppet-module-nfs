# @summary Manages idmapd
#
# @param idmap_package
#   String of the idmap package name.
#
# @param idmapd_conf_path
#   The location of the config file.
#
# @param idmapd_conf_owner
#   The owner of the config file.
#
# @param idmapd_conf_group
#   The group for the config file.
#
# @param idmapd_conf_mode
#   The mode for the config file.
#
# @param idmapd_service_name
#   String of the service name.
#
# @param idmapd_service_ensure
#   Boolean value of ensure parameter for idmapd service. Default is based
#   on the platform. If running EL7 as an nfs-server, this must be set to
#   'running'.
#
# @param idmapd_service_enable
#   Boolean value of enable parameter for idmapd service.
#
# @param idmapd_service_hasstatus
#   Boolean value of hasstatus parameter for idmapd service.
#
# @param idmapd_service_hasrestart
#   Boolean value of hasrestart parameter for idmapd service.
#
# @param idmap_domain
#   String value of domain to be set as local NFS domain.
#
# @param ldap_server
#   String value of ldap server name.
#
# @param ldap_base
#   String value of ldap search base.
#
# @param local_realms
#   String or array of local kerberos realm names.
#
# @param translation_method
#   String or array of mapping method to be used between NFS and local IDs.
#   Valid values is nsswitch, umich_ldap or static.
#
# @param nobody_user
#   String of local user name to be used when a mapping cannot be completed.
#
# @param nobody_group
#   String of local group name to be used when a mapping cannot be completed.
#
# @param verbosity
#   Integer of verbosity level.
#
# @param pipefs_directory
#   String of the directory for rpc_pipefs.
#
class nfs::idmap (
  Optional[String]       $idmap_package             = undef,
  Stdlib::Absolutepath   $idmapd_conf_path          = '/etc/idmapd.conf',
  String                 $idmapd_conf_owner         = 'root',
  String                 $idmapd_conf_group         = 'root',
  Pattern[/^[0-7]{4}$/]  $idmapd_conf_mode          = '0644',
  Optional[String]       $idmapd_service_name       = undef,
  Optional[String]       $idmapd_service_ensure     = undef,
  Boolean                $idmapd_service_enable     = true,
  Boolean                $idmapd_service_hasstatus  = true,
  Boolean                $idmapd_service_hasrestart = true,
  # idmapd.conf options
  String                                $idmap_domain       = $facts['networking']['domain'],
  Variant[Undef, String]                $ldap_server        = undef,
  Variant[Undef, String, Array]         $ldap_base          = undef,
  Variant[String, Array]                $local_realms       = $facts['networking']['domain'],
  Variant[Array,
    Pattern[/^(nsswitch|umich_ldap|static)$/]
  ]                                     $translation_method = 'nsswitch',
  String                                $nobody_user        = 'nobody',
  String                                $nobody_group       = 'nobody',
  Integer                               $verbosity          = 0,
  Variant[Undef, Stdlib::Absolutepath]  $pipefs_directory   = undef,
) {
  $is_idmap_domain_valid = is_domain_name($idmap_domain)
  if $is_idmap_domain_valid != true {
    fail("nfs::idmap::idmap_domain parameter, <${idmap_domain}>, is not a valid name.")
  }

  if $ldap_server != undef {
    $is_ldap_server_valid = is_domain_name($ldap_server)
    if $is_ldap_server_valid != true {
      fail("nfs::idmap::ldap_server parameter, <${ldap_server}>, is not a valid name.")
    }
  }

  if $idmapd_service_ensure {
    validate_re($idmapd_service_ensure, '^(stopped)|(running)|(true)|(false)$',
    'for nfs::idmapd::idmapd_service_ensure valid values are stopped, running, true and false')
  }

  package { $idmap_package:
    ensure => present,
  }

  file { 'idmapd_conf':
    ensure  => file,
    path    => $idmapd_conf_path,
    content => template('nfs/idmapd.conf.erb'),
    owner   => $idmapd_conf_owner,
    group   => $idmapd_conf_group,
    mode    => $idmapd_conf_mode,
    require => Package[$idmap_package],
  }

  if $idmapd_service_name {
    service { 'idmapd_service':
      ensure     => $idmapd_service_ensure,
      name       => $idmapd_service_name,
      enable     => $idmapd_service_enable,
      hasstatus  => $idmapd_service_hasstatus,
      hasrestart => $idmapd_service_hasrestart,
      subscribe  => File['idmapd_conf'],
    }
  }
}
