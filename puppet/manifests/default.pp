import "./core/*"
import "./phalconphp.pp"

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


class system-update {
    exec { 'apt-get update':
        command => 'apt-get update'
    }
}

class dev-packages {

    include gcc
    include wget


    package { "python-software-properties":
        ensure => present,
    }
    ->
    exec { 'add-apt-repository ppa:chris-lea/node.js':
        command => '/usr/bin/add-apt-repository ppa:chris-lea/node.js',
        require => Package["python-software-properties"],
    }
    ->
    exec { 'add-apt-repository ppa:ivanj/beanstalkd':
        command => '/usr/bin/add-apt-repository ppa:ivanj/beanstalkd',
        require => Package["python-software-properties"],
    }
    ->
    exec { 'add-apt-repository ppa:ondrej/mysql-5.6':
        command => '/usr/bin/add-apt-repository ppa:ondrej/mysql-5.6',
        require => Package["python-software-properties"],
    }
    ->
    exec { 'apt-get update 2':
        command => 'apt-get update'
    }


    $devPackages = [ "vim", "curl", "git", "nodejs", "capistrano", "rubygems", "openjdk-7-jdk", "libaugeas-ruby", "beanstalkd" ]

    package { $devPackages:
        ensure => "installed",
        require => Exec['apt-get update 2'],
    }

    exec { 'install less using npm':
        command => 'npm install less -g',
        require => Package["nodejs"],
    }

    #exec { 'install capifony using RubyGems':
    #    command => 'gem install capifony',
    #    require => Package["rubygems"],
    #}

    exec { 'install sass with compass using RubyGems':
        command => 'gem install compass',
        require => Package["rubygems"],
    }

    exec { 'install capistrano_rsync_with_remote_cache using RubyGems':
        command => 'gem install capistrano_rsync_with_remote_cache',
        require => Package["capistrano"],
    }
}

class phalconphp-setup (
  $ensure           = 'master',
  $install_devtools = true,
  $devtools_version = 'master',
  $custom_ini       = true,
  $ini_file         = "phalcon.ini",
  $debug            = false) {

  include core::params

  $phalcon_deps = [
    'autoconf',
    'make',
    'automake',
    're2c',
    'libpcre3', 'libpcre3-dev',
    # 'pcre', 'pcre-devel',
    'libssl1.0.0',
    'libssl-dev',
    'libcurl3',
    'libcurl4-openssl-dev',
    ]

  package { $phalcon_deps:
      ensure => "installed",
      require => Exec['apt-get update'],
  }
  ->
  class {'phalconphp::framework':
    version => $ensure,
    debug=>false,
    src_phalcon_ini => $core::params::src_phalcon_ini,
    require => Package["php5-fpm"],
  }

}

class elasticsearch-setup {
  include wget

  wget::fetch { 'elasticsearch':
    source => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.deb',
    destination => '/tmp/elasticsearch-1.1.0.deb'
  }
  ->
  exec { 'install elasticsearch':
      command => 'dpkg -i /tmp/elasticsearch-1.1.0.deb',
      require => Package["openjdk-7-jdk"],
  }
}

class nginx-setup {

    include nginx

    file { '/etc/nginx/sites-available/default':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/sys-conf/nginx/default',
        require => Package["nginx"],
    }

    file { "/etc/nginx/sites-enabled/default":
        notify => Service["nginx"],
        ensure => link,
        target => "/etc/nginx/sites-available/default",
        require => Package["nginx"],
    }
}

class mysql-setup {
  include core::params


  class { "mysql":
    root_password => $core::params::dbroot_password,
    require => Exec['apt-get update 2'],
  }
  ->
  mysql::grant { 'phalcon':
      mysql_privileges => 'ALL',
      mysql_password => $core::params::dbpassword,
      mysql_user => $core::params::dbuser,
      mysql_host => 'localhost',
      mysql_db => $core::params::dbname,
  }
}

class php-setup {

    $php = ["php5-fpm", "php5-cli", "php5-dev", "php5-gd", "php5-curl", "php-apc", "php5-mcrypt", "php5-xdebug", "php5-sqlite", "php5-mysql", "php5-memcache", "php5-intl", "php5-tidy", "php5-imap", "php5-imagick"]

    exec { 'add-apt-repository ppa:ondrej/php5':
        command => '/usr/bin/add-apt-repository ppa:ondrej/php5',
        require => Package["python-software-properties"],
    }

    exec { 'apt-get update for ondrej/php5':
        command => '/usr/bin/apt-get update',
        before => Package[$php],
        require => Exec['add-apt-repository ppa:ondrej/php5'],
    }

    #package { "mongodb":
    #    ensure => present,
    #    require => Package[$php],
    #}

    package { $php:
        notify => Service['php5-fpm'],
        ensure => latest,
    }

    package { "apache2.2-bin":
        notify => Service['nginx'],
        ensure => purged,
        require => Package[$php],
    }

    package { "imagemagick":
        ensure => present,
        require => Package[$php],
    }

    package { "libmagickwand-dev":
        ensure => present,
        require => Package["imagemagick"],
    }

    package { "phpmyadmin":
        ensure => present,
        require => Package[$php],
    }

    #exec { 'pecl install mongo':
    #    notify => Service["php5-fpm"],
    #    command => '/usr/bin/pecl install --force mongo',
    #    logoutput => "on_failure",
    #    require => Package[$php],
    #    before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
    #    unless => "/usr/bin/php -m | grep mongo",
    #}

    file { '/etc/php5/cli/php.ini':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/sys-conf/php/cli/php.ini',
        require => Package[$php],
    }

    file { '/etc/php5/fpm/php.ini':
        notify => Service["php5-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/sys-conf/php/fpm/php.ini',
        require => Package[$php],
    }

    file { '/etc/php5/fpm/php-fpm.conf':
        notify => Service["php5-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/sys-conf/php/fpm/php-fpm.conf',
        require => Package[$php],
    }

    file { '/etc/php5/fpm/pool.d/www.conf':
        notify => Service["php5-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/sys-conf/php/fpm/pool.d/www.conf',
        require => Package[$php],
    }

    service { "php5-fpm":
        ensure => running,
        require => Package["php5-fpm"],
    }

    #service { "mongodb":
    #    ensure => running,
    #    require => Package["mongodb"],
    #}
}

class composer {
    exec { 'install composer php dependency management':
        command => 'curl -s http://getcomposer.org/installer | php -- --install-dir=/usr/bin && mv /usr/bin/composer.phar /usr/bin/composer',
        creates => '/usr/bin/composer',
        require => [Package['php5-cli'], Package['curl']],
    }

    exec { 'composer self update':
        command => 'composer self-update',
        require => [Package['php5-cli'], Package['curl'], Exec['install composer php dependency management']],
    }
}

class memcached {
    package { "memcached":
        ensure => present,
    }
}

class { 'apt':
    always_apt_update    => true
}



Exec["apt-get update"] -> Package <| |>

include mysql-setup
include system-update
include dev-packages
include nginx-setup
include php-setup

class { "phalconphp-setup" :}
include composer
include phpqatools
include memcached
include redis

include elasticsearch-setup

