# These functions provide the same values as used in hiera

def include_rpcbind(facts)
  if facts[:os]['family'] == 'RedHat'
    true
  else
    false
  end
end

def include_idmap(facts)
  if facts[:os]['family'] == 'RedHat' || facts[:os]['family'] == 'Suse'
    true
  else
    false
  end
end

def nfs_package(facts)
  if facts[:os]['family'] == 'RedHat'
    ['nfs-utils']
  else
    ['nfs-client']
  end
end

def nfs_service(facts)
  if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 6 || facts[:os]['family'] == 'Suse'
    'nfs'
  else
    nil
  end
end

def nfs_service_ensure(facts)
  if facts[:os]['family'] == 'Suse'
    'running'
  else
    'stopped'
  end
end

def nfs_service_enable(facts)
  if facts[:os]['family'] == 'Suse'
    true
  else
    false
  end
end

def idmap_package(facts)
  if facts[:os]['family'] == 'Suse'
    'nfsidmap'
  elsif facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 6
    'nfs-utils-lib'
  else
    'libnfsidmap'
  end
end

def idmapd_service_name(facts)
  if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 6
    'rpcidmapd'
  elsif facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 7
    'nfs-idmap'
  elsif facts[:os]['family'] == 'RedHat'
    'nfs-idmapd'
  end
end

def idmapd_service_ensure(facts)
  if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 6
    'running'
  elsif facts[:os]['family'] == 'RedHat'
    'stopped'
  end
end
