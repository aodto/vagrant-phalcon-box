# Class: core::params
#
#
class core::params
{
  # Puppet variables
  $puppet_dir    = "/vagrant/puppet"
  $files_dir     = "$puppet_dir/files"


  $src_phalcon_ini =  "$files_dir/phalcon.ini"

  # Database variables
  $dbname     = "phalcon"
  $dbuser     = "vagrant"
  $dbpassword = "vagrant"
  $dbroot_password = "root"
}
