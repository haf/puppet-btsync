# == Define: btsync::shared_folder
#
#   Configure a shared folder
#
# === Parameters
#
# [*instance*]
#   Name of the instance sharing this folder.
#
# [*dir*]
#   Directory to share.
#
# [*secret*]
#   Shared secret. Defaults to resource name.
#
# [*use_relay_server*]
#   Whether or not use relay server when direct connection fails. Defaults to
#   `true`.
#
# [*use_tracker*]
#   can be enabled to facilitate communication between peers.
#
# [*use_dht*]
#
# [*search_lan*]
#
# [*use_sync_trash*]
#   Whether or not save all the files deleted on other clients to the hidden
#   '.SyncArchive' within your destination folder. The files deleted on your
#   computer are moved to system Trash (depending on OS preferences).
#
# [*known_hosts*]
#   An array containing the ip:port or host:port of known clients. So if one of
#   your devices has a static and accessible IP, peers can connect to it
#   directly.
#
# === Author
#
# Mickaël Canévet <mickael.canevet@gmail.com>
#
# === Copyright
#
# Copyright 2013 Mickaël Canévet, unless otherwise noted.
#
define btsync::shared_folder(
  $instance,
  $dir,
  $secret = $name,
  $use_relay_server = true,
  $use_tracker = true,
  $use_dht = true,
  $search_lan = true,
  $use_sync_trash = true,
  $known_hosts = [],
) {
  if ! defined(Concat_build["btsync_${instance}_json_shared_folders"]) {
    concat_build { "btsync_${instance}_json_shared_folders":
      parent_build => "btsync_${instance}_json",
      target       => "/var/lib/puppet/concat/fragments/btsync_${instance}_json/03",
    }

    concat_fragment { "btsync_${instance}_json_shared_folders+01":
      content => '
  "shared_folders":
  [',
    }

    # FIXME: when a concat_build contains no fragment but only a concat_build
    # The "fragments" directory is not created and it fails with "No fragments
    # specified for group", so we have to:
    # - create the directory explicitely,
    # - use "quiet => true" for concat_build
    # This is quite ugly though...
    file { "/var/lib/puppet/concat/fragments/btsync_${instance}_json_shared_folders_json":
      ensure => directory,
    }
    ->
    concat_build { "btsync_${instance}_json_shared_folders_json":
      parent_build   => "btsync_${instance}_json_shared_folders",
      target         => "/var/lib/puppet/concat/fragments/btsync_${instance}_json_shared_folders/02",
      file_delimiter => ',',
      append_newline => false,
      quiet          => true,
    }

    concat_fragment { "btsync_${instance}_json_shared_folders+99":
      content => '  ]',
    }
  }

  concat_build { "btsync_${instance}_json_shared_folders_json_${secret}":
    parent_build => "btsync_${instance}_json_shared_folders_json",
    target       => "/var/lib/puppet/concat/fragments/btsync_${instance}_json_shared_folders_json/${secret}",
  }

  concat_fragment { "btsync_${instance}_json_shared_folders_json_${secret}+01":
    content => '    {',
  }

  concat_build { "btsync_${instance}_json_shared_folders_json_${secret}_json":
    parent_build   => "btsync_${instance}_json_shared_folders_json_${secret}",
    target         => "/var/lib/puppet/concat/fragments/btsync_${instance}_json_shared_folders_json_${secret}/02",
    file_delimiter => ',',
    append_newline => false,
  }

  concat_fragment { "btsync_${instance}_json_shared_folders_json_${secret}+99":
    content => '    }
',
  }

  concat_fragment { "btsync_${instance}_json_shared_folders_json_${secret}_json+01":
    content => template('btsync/shared_folder.erb'),
  }

  $listening_port = getparam(Btsync::Instance[$instance], 'listening_port')
  $host = $listening_port ? {
    0       => $::ipaddress,
    default => "${::ipaddress}:${listening_port}",
  }

  @@btsync::known_host { "exported ${secret} on ${::hostname}":
    secret   => $secret,
    host     => $host,
    instance => $instance,
  }

  Btsync::Known_host <<| secret == $secret |>>

  $_known_hosts = prefix($known_hosts, "${secret} on ")
  btsync::known_host { $_known_hosts:
    secret   => $secret,
    instance => $instance,
  }

}
