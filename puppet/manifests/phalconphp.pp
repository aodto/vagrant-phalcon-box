# Class: phalconphp::framework
# Installs the actual phalconphp framework
class phalconphp::framework (
  $version = 'master',
  $debug = false,
  $src_phalcon_ini
) {
  exec { 'git-clone-phalcon':
    command   => "git clone -b ${version} https://github.com/phalcon/cphalcon.git",
    cwd       => '/vagrant',
    unless    => 'test -d /vagrant/cphalcon',
    logoutput => $debug,
    timeout   => 0
  } ->
  exec { 'git-pull-phalcon':
    command   => 'git pull',
    cwd       => '/vagrant/cphalcon',
    onlyif    => 'test -d /vagrant/cphalcon',
    logoutput => $debug,
    timeout   => 0
  }


  exec { 'install-phalcon-1.x':
    command   => 'sudo ./install',
    cwd       => '/vagrant/cphalcon/build',
    onlyif    => 'test -f /vagrant/cphalcon/build/install',
    require   => [Exec['git-pull-phalcon']],
    logoutput => $debug,
    timeout   => 0
  }

#  exec { 'remove-phalcon-src-1.x':
#    cwd       => '/vagrant',
#    command   => 'rm ./cphalcon -R  -f',
#    require   => [
#      Exec['git-pull-phalcon'],
#      Exec['install-phalcon-1.x']],
#    logoutput => $debug,
#    timeout   => 0
#  }

  file { "/etc/php5/mods-available/phalcon.ini" :
    source => $src_phalcon_ini,
    ensure  => file,
    mode => 644,
    require => Exec['install-phalcon-1.x'],
  }
  ->
  file { "/etc/php5/fpm/conf.d/30-phalcon.ini" :
    ensure  => link,
    target => "/etc/php5/mods-available/phalcon.ini",
  }
  ->
  file { "/etc/php5/cli/conf.d/30-phalcon.ini" :
    ensure  => link,
    target => "/etc/php5/mods-available/phalcon.ini",
  }
}
