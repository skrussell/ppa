# == Define: ppa::key
#
# The define must be used to add additional pgp-keys for package repositories
# to the apt-keylist.
#
# The keys will be retrieved from the given keyserver and added or removed from
# the list depending on the value of the attribute ensure.
#
# The resource is based on the official puppet resource from
# http://projects.puppetlabs.com/projects/1/wiki/Apt_Keys_Patterns
#
# === Parameters
#
# [*namevar*]
#   The name of the resource is the unique number of the key to be added.
#
# [*ensure*]
#   With the value 'present' the given key will be listed in the key store for
#   apt. If the value is 'absent' the key will be removed from the key store.
#
# [*keyserver*]
#   The name of the server to retrieve the give from. The default key server is
#   keyserver.ubuntu.com.
#
# === Examples
#
#  ppa::key { '7CC17CD2':
#  }
#
#  ppa::key { '7CC17CD2':
#    ensure => present,
#  }
#
#  ppa::key { '7CC17CD2':
#    ensure => absent,
#  }
#
# === Authors
#
# Daniel Hahler @blueyed
# Sebastian Hempel <shempel@it-hempel.de>
#
# === Copyright
#
# Copyright 2011 Daniel Hahler
# Copyright 2013 Sebastian Hempel
#
define ppa::key(
  $ensure = present,
  $keyserver = 'keyserver.ubuntu.com'
) {
  $key_len = length($name)
  if ($key_len != 8) {
    fail("Unexpected key length of ${key_len}")
  }

  if ($facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '18.04') >= 0) {
    # They seem to have defaulted to using the finger print view/output for list now, so have to insert a space to match it
    $use_match_key = regsubst($name, /^(\w{4})(\w{4})$/, '\1\ \2')
  } else {
    $use_match_key = $name
  }
  $match_cmd = "apt-key list | grep ${use_match_key}"
  case $ensure {
    present: {
      exec { "Import ${name} to apt keystore":
        path        => '/bin:/usr/bin',
        environment => 'HOME=/root',
        command     => "gpg --keyserver ${keyserver} --recv-keys ${name} && \
                        gpg --export --armor ${name} | apt-key add -",
        user        => 'root',
        group       => 'root',
        unless      => $match_cmd,
        logoutput   => on_failure,
      }
    }
    absent:  {
      exec { "Remove ${name} from apt keystore":
        path        => '/bin:/usr/bin',
        environment => 'HOME=/root',
        command     => "apt-key del ${name}",
        user        => 'root',
        group       => 'root',
        onlyif      => $match_cmd,
      }
    }
    default: {
      fail "Invalid 'ensure' value '${ensure}' for ppa::key"
    }
  }
}
