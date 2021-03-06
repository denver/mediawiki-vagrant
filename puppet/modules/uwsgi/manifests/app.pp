# == Define: uwsgi:app
#
# Provisions a uWSGI application server instance.
#
# === Parameters
#
# [*settings*]
#   Hash of hashes, representing the app configuration. Each key of the
#   top-level hash is used as a section in the app's ini file. If a second
#   level key has a value that is an Array, that key is repeated for each
#   value of the array
#
# === Examples
#
#  uwsgi::app { 'graphite-web':
#    settings => {
#      uwsgi => {
#          'plugins'     => 'python',
#          'socket'      => '/var/run/graphite-web/graphite-web.sock',
#          'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
#          'master'      => true,
#          'processes'   => 4,
#          'env'         => ['MYSQL_HOST=localhost', 'STATSD_PREFIX=wat'],
#      },
#    },
#  }
#
define uwsgi::app(
    $settings,
    $ensure   = present,
    $enabled  = true,
) {
    include ::uwsgi

    $basename = regsubst($title, '\W', '-', 'G')

    if $ensure == 'present' {
        file { "/etc/uwsgi/apps-available/${basename}.ini":
            content => template('uwsgi/app.ini.erb'),
        }

        if $enabled == true {
            $inipath =  "/etc/uwsgi/apps-enabled/${basename}.ini"
            file { $inipath:
                ensure => link,
                target => "/etc/uwsgi/apps-available/${basename}.ini",
            }

            systemd::service { "uwsgi-${title}":
                ensure        => present,
                template_name => 'uwsgi',
                subscribe     => File["/etc/uwsgi/apps-available/${basename}.ini"],
            }
        }
    }
}
