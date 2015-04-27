# Class redmine::params
class redmine::params {

  case $::osfamily {
    'RedHat': {
      case $::operatingsystem {
        'Fedora': {
          if versioncmp($::operatingsystemrelease, '19') >= 0 or $::operatingsystemrelease == 'Rawhide' {
            $mysql_devel = 'mariadb-devel'
          } else {
            $mysql_devel = 'mysql-devel'
          }
        }
        /^(RedHat|CentOS|Scientific)$/: {
          if versioncmp($::operatingsystemmajrelease, '7') >= 0 {
            $mysql_devel = 'mariadb-devel'
          } else {
            $mysql_devel = 'mysql-devel'
          }
        }
        default: {
          $mysql_devel = 'mysql-devel'
        }
      }
    }
  }

  case $redmine::database_adapter {
    'mysql', 'mariadb': {
      $real_adapter = 'mysql'
    }
    'mysql2', 'mariadb2': {
      $real_adapter = 'mysql'
    }
    'postgresql': {
      $real_adapter = 'postgresql'
    }
    default : {
      if versioncmp($::rubyversion, '1.9') >= 0 {
        $real_adapter = 'mysql2'
      } else {
        $real_adapter = 'mysql'
      }
    }
  }

  if $redmine::version {
    $version = $redmine::version
  } else {
    $version = '2.2.3'
    warning('The default version will change to 2.6.4 in the next major release')
    warning('If this is not what you want, please specify a version in hiera or your manifest')
  }

  case $redmine::provider {
    'svn' : {
      $provider_package = 'subversion'
    }
    'hg': {
      $provider_package = 'mercurial'
    }
    default: {
      $provider_package = $redmine::provider
    }
  }
}
