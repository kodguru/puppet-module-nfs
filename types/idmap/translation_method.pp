# Datatype for nfs::idmap::tTranslation_method
type Nfs::Idmap::Translation_method = Variant[
  Array[Pattern[/^(nsswitch|umich_ldap|static)$/]],
  Pattern[/^(nsswitch|umich_ldap|static)$/],
]
