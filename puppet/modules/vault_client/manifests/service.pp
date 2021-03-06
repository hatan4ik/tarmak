class vault_client::service {

  $systemd_dir = '/etc/systemd/system'
  $service_name = $::vault_client::token_service_name
  $frequency = 86400

  $path = defined('$::path') ? {
    default => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin',
    true    => $::path
  }

  if $::vault_client::run_exec {
    $trigger_command = "systemctl start ${service_name}.service"
  } else {
    $trigger_command = '/bin/true'
  }

  exec { "${module_name}-systemctl-daemon-reload":
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    path        => $path,
  }

  file { "${systemd_dir}/${service_name}.service":
    ensure  => file,
    content => template('vault_client/token-renewal.service.erb'),
    notify  => Exec["${module_name}-systemctl-daemon-reload"],
  }
  ~> exec { "${service_name}-trigger":
    command     => $trigger_command,
    path        => $path,
    refreshonly => true,
    require     => Exec["${module_name}-systemctl-daemon-reload"],
  }

  file { "${systemd_dir}/${service_name}.timer":
    ensure  => file,
    content => template('vault_client/token-renewal.timer.erb'),
    notify  => Exec["${module_name}-systemctl-daemon-reload"],
  }
  ~> service { "${service_name}.timer":
    ensure => 'running',
    enable => true,
  }

}
