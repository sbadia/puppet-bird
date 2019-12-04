# @summary Install and configure bird
# @author Sebastien Badia <http://sebastien.badia.fr/>
# @author Lorraine Data Network <http://ldn-fai.net/>
#
# @param config_file_v4
#   Bird configuration file for IPv4.
#
# @param config_template_v4
#   Bird configuration template for IPv4. This value is a template source, it
#   will be passed into the template() function.
#
# @param daemon_name_v6
#   The service name used by puppet resource
#
# @param package_name_v6
#   The package name used by puppet resource
#
# @param daemon_name_v4
#   The service name used by puppet resource
#
# @param package_name_v4
#   The package name used by puppet resource
#
# @param config_path_v6
#   The full path of the v6 configuration file
#
# @param config_path_v4
#   The full path of the v4 configuration file
#
# @param enable_v6
#   Boolean for enable IPv6 (install bird6 package)
#
# @param manage_conf
#   Boolean, global parameter to disable or enable mangagment of bird configuration files.
#
# @param manage_service
#   Boolean, global parameter to disable or enable mangagment of bird service.
#
# @param service_v6_ensure
#   Bird IPv6 daemon ensure (shoud be running or stopped).
#
# @param service_v6_enable
#   Boolean, enabled param of Bird IPv6 service (run at boot time).
#
# @param service_v4_ensure
#   Bird IPv4 daemon ensure (shoud be running or stopped).
#
# @param service_v4_enable
#   Boolean, enabled param of Bird IPv4 service (run at boot time).
#
# @param config_file_v6
#  Bird configuration file for IPv6.
#
# @param config_template_v6
#   Bird configuration template for IPv6. This value is a template source, it
#   will be passed into the template() function.
#
# @param manage_repository
#   Add the upstream repository from CZ.NIC. This is currently only supported for CentOS 7
# @example IPv4 only
#   class { 'bird':
#     config_file_v4 => 'puppet:///modules/bgp/ldn/bird.conf',
#   }
#
# @example Both IPv4 and IPv6
#   class { 'bird':
#     enable_v6      => true,
#     config_file_v4 => 'puppet:///modules/bgp/ldn/bird.conf',
#     config_file_v6 => 'puppet:///modules/bgp/ldn/bird6.conf',
#   }
#
class bird (
  String[1] $daemon_name_v4                     = 'bird',
  String[1] $package_name_v4                    = 'bird',
  Stdlib::Absolutepath $config_path_v4          = $bird::params::config_path_v4,
  Optional[Stdlib::Filesource] $config_file_v4  = undef,
  Optional[String[1]] $config_template_v4       = undef,
  Boolean $enable_v6                            = false,
  Boolean $manage_conf                          = false,
  Boolean $manage_service                       = false,
  Stdlib::Ensure::Service $service_v6_ensure    = 'running',
  Boolean $service_v6_enable                    = false,
  Stdlib::Ensure::Service $service_v4_ensure    = 'running',
  Boolean $service_v4_enable                    = false,
  String[1] $daemon_name_v6                     = 'bird6',
  String[1] $package_name_v6                    = $bird::params::package_name_v6,
  Stdlib::Absolutepath $config_path_v6          = $bird::params::config_path_v6,
  Optional[Stdlib::Filesource] $config_file_v6  = undef,
  Optional[String[1]] $config_template_v6       = undef,
  Boolean $manage_repository                    = false,
) inherits bird::params {

  if $manage_repository {
    yumrepo{'bird':
      baseurl  => 'ftp://bird.network.cz/pub/bird/centos/7/x86_64/',
      descr    => 'Official bird packages from CZ.NIC',
      enabled  => 1,
      gpgcheck => 1,
      gpgkey   => 'ftp://bird.network.cz/pub/bird/centos/7/x86_64/RPM-GPG-KEY-network.cz',
    }
    # set a dependency to package resources
    $dependency = Yumrepo['bird']
  } else {
    $dependency = undef
  }

  ensure_packages([$package_name_v4], {'ensure' => 'present', 'require' => $dependency})

  if $manage_service {
    service { $daemon_name_v4:
      ensure     => $service_v4_ensure,
      enable     => $service_v4_enable,
      hasrestart => false,
      restart    => '/usr/sbin/birdc configure',
      hasstatus  => false,
      pattern    => $daemon_name_v4,
      require    => Package[$package_name_v4];
    }
  }

  if $manage_conf {
    unless $config_file_v4 or $config_template_v4 {
      fail("either config_file_v4 or config_template_v4 parameter must be set (config_file_v4: ${config_file_v4}, config_template_v4: ${config_template_v4})")
    }

    if $config_file_v4 {
      $config_file_v4_content = undef
    } else {
      $config_file_v4_content = template($config_template_v4)
    }

    file { $config_path_v4:
      ensure  => file,
      source  => $config_file_v4,
      content => $config_file_v4_content,
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package[$package_name_v4];
    }

    if $manage_service {
      File[$config_path_v4] ~> Service[$daemon_name_v4]
    }
  }

  if $enable_v6 {

    ensure_packages([$package_name_v6], {'ensure' => 'present', 'require' => $dependency})

    if $manage_service {
      service { $daemon_name_v6:
        ensure     => $service_v6_ensure,
        enable     => $service_v6_enable,
        hasrestart => false,
        restart    => '/usr/sbin/birdc6 configure',
        hasstatus  => false,
        pattern    => $daemon_name_v6,
        require    => Package[$package_name_v6];
      }
    }

    if $manage_conf {
      unless $config_file_v6 or $config_template_v6 {
        fail("either config_file_v6 or config_template_v6 parameter must be set (config_file_v6: ${config_file_v6}, config_template_v6: ${config_template_v6})")
      }

      if $config_file_v6 {
        $config_file_v6_content = undef
      } else {
        $config_file_v6_content = template($config_template_v6)
      }

      file { $config_path_v6:
        ensure  => file,
        source  => $config_file_v6,
        content => $config_file_v6_content,
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Package[$package_name_v6];
      }

      if $manage_service {
        File[$config_path_v6] ~> Service[$daemon_name_v6]
      }
    }
  }

}
