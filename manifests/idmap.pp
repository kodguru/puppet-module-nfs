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
  Optional[String[1]]                   $idmap_package             = undef,
  Stdlib::Absolutepath                  $idmapd_conf_path          = '/etc/idmapd.conf',
  String[1]                             $idmapd_conf_owner         = 'root',
  String[1]                             $idmapd_conf_group         = 'root',
  Stdlib::Filemode                      $idmapd_conf_mode          = '0644',
  Optional[String[1]]                   $idmapd_service_name       = undef,
  Optional[Stdlib::Ensure::Service]     $idmapd_service_ensure     = undef,
  Boolean                               $idmapd_service_enable     = true,
  Boolean                               $idmapd_service_hasstatus  = true,
  Boolean                               $idmapd_service_hasrestart = true,
  # idmapd.conf options
  Stdlib::Fqdn                          $idmap_domain              = $facts['networking']['domain'],
  Optional[Stdlib::Fqdn]                $ldap_server               = undef,
  Optional[Variant[String[1], Array[String[1]]]]
                                        $ldap_base                 = undef,
  Nfs::Idmap::Local_realms              $local_realms              = $facts['networking']['domain'],
  Nfs::Idmap::Translation_method        $translation_method        = 'nsswitch',
  String[1]                             $nobody_user               = 'nobody',
  String[1]                             $nobody_group              = 'nobody',
  Integer                               $verbosity                 = 0,
  Optional[Stdlib::Absolutepath]        $pipefs_directory          = undef,
) {
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
