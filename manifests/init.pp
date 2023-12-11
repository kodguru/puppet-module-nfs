# @summary Manages NFS
#
# @param include_rpcbind
#   Include rpcbind into catalogue.
#
# @param include_idmap
#   Include nfs::idmap into catalogue.
#
# @param nfs_package
#   Name of the NFS package. May be a string or an array.
#
# @param nfs_service
#   Name of the NFS service.
#
# @param nfs_service_ensure
#   Ensure attribute for the NFS service.
#
# @param nfs_service_enable
#   Enable attribute for the NFS service.
#
# @param mounts
#   Hash of mounts to be mounted on system.
#
# @param server
#   Boolean to specify if the system is an NFS server.
#
# @param exports_path
#   The location of the config file.
#
# @param exports_owner
#   The owner of the config file.
#
# @param exports_group
#   The group for the config file.
#
# @param exports_mode
#   The mode for the config file.
#
class nfs (
  Boolean                              $include_rpcbind    = false,
  Boolean                              $include_idmap      = false,
  Variant[Array[String[1]], String[1]] $nfs_package        = undef,
  Optional[String[1]]                  $nfs_service        = undef,
  Stdlib::Ensure::Service              $nfs_service_ensure = 'stopped',
  Boolean                              $nfs_service_enable = false,
  Optional[Hash]                       $mounts             = undef,
  Boolean                              $server             = false,
  Stdlib::Absolutepath                 $exports_path       = '/etc/exports',
  String[1]                            $exports_owner      = 'root',
  String[1]                            $exports_group      = 'root',
  Stdlib::Filemode                     $exports_mode       = '0644',
) {
  if $include_rpcbind {
    include rpcbind
  }

  if $include_idmap {
    include nfs::idmap
  }

  if $facts['os']['family'] == 'Suse' and $server == true {
    fail('This platform is not configured to be an NFS server.')
  }

  $nfs_package_array = any2array($nfs_package)

  if $server == true {
    $nfs_service_ensure_real = 'running'
    $nfs_service_enable_real = true
  } else {
    $nfs_service_ensure_real = $nfs_service_ensure
    $nfs_service_enable_real = $nfs_service_enable
  }

  package { $nfs_package_array:
    ensure => present,
  }

  if $server == true {
    file { 'nfs_exports':
      ensure => file,
      path   => $exports_path,
      owner  => $exports_owner,
      group  => $exports_group,
      mode   => $exports_mode,
      notify => Exec['update_nfs_exports'],
    }

    exec { 'update_nfs_exports':
      command     => 'exportfs -ra',
      path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      refreshonly => true,
    }

    $service_require = 'Exec[update_nfs_exports]'
  } else {
    $service_require = undef
  }

  if $nfs_service {
    # Some implmentations of NFS still need to run a service for the client
    # even though the system is not an NFS server.
    service { 'nfs_service':
      ensure     => $nfs_service_ensure_real,
      name       => $nfs_service,
      enable     => $nfs_service_enable_real,
      hasstatus  => true,
      hasrestart => true,
      require    => $service_require,
      subscribe  => Package[$nfs_package_array],
    }
  }

  if $mounts != undef {
    $mounts.each |$k,$v| {
      ::types::mount { $k:
        * => $v,
      }
    }
  }
}
