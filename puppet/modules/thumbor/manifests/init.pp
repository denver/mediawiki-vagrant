# == Class: Thumbor
#
# This Puppet class installs and configures a Thumbor instance
#
# Thumbor is installed as a Python package, and as part of that,
# pip compiles lxml.
#
# === Parameters
#
# [*deploy_dir*]
#   Path where Thumbor should be installed (example: '/var/thumbor').
#
# [*cfg_file*]
#   Thumbor configuration file. The file will be generated by Puppet.
#
# [*statsd_port*]
#   Port the statsd instance runs on.
#
# [*sentry_dsn_file*]
#   Path to file containing the sentry dsn file.
#
class thumbor (
    $deploy_dir,
    $cfg_file,
    $statsd_port,
    $sentry_dsn_file,
) {
    require ::virtualenv
    # Needed by the venv, which clones a few git repos
    require ::git

    # jpegtran
    require_package('libjpeg-progs')

    # exiftool is needed by exif-optimizer
    require_package('libimage-exiftool-perl')

    # For Pillow
    require_package('libjpeg-dev')

    # For GIF engine
    require_package('gifsicle')

    # For SVG engine
    require_package('librsvg2-bin')

    # For Video engine
    require_package('ffmpeg')

    # For XCF engine
    require_package('xcftools')

    # For DjVu engine
    require_package('djvulibre-bin')

    # For Ghostscript engine (PDF)
    require_package('ghostscript')

    # For pycurl, a dependency of thumbor
    require_package('libcurl4-gnutls-dev')

    # For lxml, a dependency of thumbor-plugins
    require_package('libxml2-dev', 'libxslt1-dev')

    $statsd_host = 'localhost'
    $statsd_prefix = 'Thumbor'

    group { 'thumbor':
        ensure => present,
    }

    user { 'thumbor':
        ensure  => present,
        home    => '/var/run/thumbor',
        gid     => 'thumbor',
        require => Group['thumbor'],
    }

    virtualenv::environment { $deploy_dir:
        ensure   => present,
        packages => [
            'numpy',
            'raven',
            'python-swiftclient',
            'git+git://github.com/gi11es/thumbor.git',
            'git+git://github.com/thumbor-community/core',
            'git+https://phabricator.wikimedia.org/diffusion/THMBREXT/thumbor-plugins.git',
        ],
        require  => [
            Package['libjpeg-progs'],
            # Needs to be an explicit dependency, for the packages pointing to git repos
            Package['git'],
            Package['libcurl4-gnutls-dev'],
            Package['libxml2-dev'],
            Package['libxslt1-dev'],
            Package['libjpeg-dev'],
        ],
        timeout  => 600, # This venv can be particularly long to download and setup
    }

    file { "${deploy_dir}/tinyrgb.icc":
        ensure => present,
        source => 'puppet:///modules/thumbor/tinyrgb.icc',
    }

    file { $cfg_file:
        ensure    => present,
        group     => 'thumbor',
        content   => template('thumbor/thumbor.conf.erb'),
        mode      => '0640',
        subscribe => File[$sentry_dsn_file],
        require   => User['thumbor'],
    }

    cgroup::config { 'thumbor':
        limits  => "perm { task { uid = thumbor; gid = thumbor; } admin { uid = thumbor; gid = thumbor; } } memory { memory.limit_in_bytes = \"1048576000\"; }", # 1GB
        cgrules => '@thumbor memory thumbor',
    }

    # This will generate a list of ports starting at 8889, with
    # as many ports as there are CPUs on the machine.
    $ports = sequence_array(8889, inline_template('<%= `nproc` %>'))

    thumbor::service { $ports:
        deploy_dir => $deploy_dir,
        cfg_file   => $cfg_file,
    }

    varnish::backend { 'swift':
        host   => '127.0.0.1',
        port   => $::swift::port,
        onlyif => 'req.url ~ "^/images/.*"',
    }

    varnish::config { 'thumbor':
        content => template('thumbor/varnish.vcl.erb'),
        order   => 49, # Needs to be before default for vcl_recv override
    }
}
