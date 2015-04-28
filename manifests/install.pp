# Class redmine::install
class redmine::install {

  # Install dependencies

  $generic_packages = [ 'make', 'gcc' ]
  $redhat_packages  = [ 'postgresql-devel', 'sqlite-devel', 'ImageMagick-devel', 'ruby-devel', $::redmine::params::mysql_devel ]

  case $redmine::database_adapter {
    'postgresql' : {
      $debian_packages = ['libmysql++-dev', 'libmagickcore-dev', 'libmagickwand-dev', 'ruby-dev', 'imagemagick', 'libpq-dev']
    }
    'mysql', 'mysql2' : {
      $debian_packages = ['libmysql++-dev', 'libmagickcore-dev', 'libmagickwand-dev', 'ruby-dev', 'imagemagick', 'libmysqlclient-dev']
    }
    'mariadb', 'mariadb2' : {
      $debian_packages = ['libmysql++-dev', 'libmagickcore-dev', 'libmagickwand-dev', 'ruby-dev', 'imagemagick', 'libmariadbclient-dev']
    }
    default: {
      $debian_packages = ['libmysql++-dev', 'libmagickcore-dev', 'libmagickwand-dev', 'ruby-dev', 'imagemagick', 'libmysqlclient-dev', 'libpq-dev']
    }
  }

  case $::osfamily {
    'Debian':   { $packages = concat($generic_packages, $debian_packages) }
    'RedHat':   { $packages = concat($generic_packages, $redhat_packages) }
    default:    { $packages = concat($generic_packages, $redhat_packages) }
  }

  ensure_packages($packages, {'ensure' => 'installed'})

  case $redmine::database_adapter {
    'postgresql' : {
      $without_gems = 'development test sqlite mysql'
    }
    default: {
      $without_gems = 'development test sqlite postgresql'
    }
  }

  Exec {
    cwd  => '/usr/src',
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ]
  }

  package { 'bundler':
    ensure   => present,
    provider => gem
  } ->

  exec { 'bundle_redmine':
    command => "bundle install --gemfile ${redmine::install_dir}/Gemfile --without ${without_gems}",
    creates => "${redmine::install_dir}/Gemfile.lock",
    require => [ Package['bundler'], Package['make'], Package['gcc'], Package[$packages] ],
    notify  => Exec['rails_migrations'],
  }

  create_resources('redmine::plugin', $redmine::plugins)

  if $redmine::provider != 'wget' {
    exec { 'bundle_update':
      cwd         => $redmine::install_dir,
      command     => 'bundle update',
      refreshonly => true,
      subscribe   => Vcsrepo['redmine_source'],
      notify      => Exec['rails_migrations'],
      require     => Exec['bundle_redmine'],
    }
  }
}
