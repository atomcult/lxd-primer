# LXD: An Opinionated Primer

* [Getting Started](#getting-started)
* [Remotes](#remotes)
* [Profiles (Annotated)](#profiles-(annotated))
  * [Basics](#basics)
  * [Profile as Root](#profile-as-root)
  * [Profile as a Non-root User](#profile-as-a-non-root-user)
* [Aliases](#aliases)

## Getting Started
```sh
sudo snap install lxd
sudo lxd init --auto

NOTE: You will have to re-login after adding yourself to a group.
sudo usermod -a -G lxd "$(whoami)"

# Launch an Ubuntu 22.04 container called "jammy"
lxc launch ubuntu:22.04 jammy

# Launch a root shell
lxc shell jammy

# Confirm that we're in a 22.04 container
cat /etc/lsb-release

# Exit and destroy the container
exit
lxc stop jammy
lxc rm jammy

# Confirm there are no more containers
lxc ls
```

## Remotes

The 2 remotes you're likely to see:

- **ubuntu**
  - ubuntu:22.04
  - ubuntu:20.04
  - ubuntu:18.04
  - etc.
- **images**
  - images:ubuntu/jammy
  - images:centos/8
  - images:archlinux/current
  - etc.

By default, images from the `ubuntu` remote support cloud-init. This is not the case for other remotes. AFAIK you can choose a cloud variant of images provided by the `images` remote, that do include cloud-init support.

You can check all the remotes that are set up with
```sh
lxc remote ls
```

## Profiles (Annotated)

Profiles allow you to set up a container with a default set of instance configuration values as if you had set them manually with `lxd config ...`. As such, any configuration that can be set through the `lxd config` facilities also works with profiles. Additionally, `cloud-init` allows for first-time setup when the container is created.

For more information about configuring profiles, refer to the following documents. There are *many, many* things that can be configured that are not touched upon in this primer.
 - [LXD Profile Configuration Docs](https://linuxcontainers.org/lxd/docs/master/profiles/)
 - [LXD Instance Configuration Docs](https://linuxcontainers.org/lxd/docs/master/instances/)
 - [LXD cloud-init Docs](https://linuxcontainers.org/lxd/docs/master/cloud-init/)

### Basics

To create a profile you can either create a new one from scratch
```
lxc profile create <profile>
```

or copy from an already existing profile.
```
lxc profile copy <profile> <new-profile>
```

Once created, a profile has can be set or viewed one property at a time, but it's usually easier to edit the entire YAML configuration with
```
lxc profile edit <profile>
```

You can verify your work with
```
lxc profile show <profile>
```

The profile can now be used when launching an instance (potentially in combination with others):
```
lxc launch ubuntu:22.04 -p <profile>[,<profile-2>,...] <container-name>
```

### Profile as Root
```yaml
config:
  # Map host user $(id -u) to the root user in the container.
  # This means that files from the host system that are mounted into
  #   the container will appear as though they belong to root (you).
  #   This also means that any files you create as root within the
  #   container will be owned by your user on the host system.
  raw.idmap: both 1000 0

  # Setup cloud-init.
  # cloud-init allows for first-time setup when the container is created.
  # NOTE: If you want compatability with Ubuntu images 20.04 and earlier,
  #       this *needs* to be `user.user-data`, **NOT** cloud-init.user-data
  # NOTE: This does not work with all LXD images by default! ubuntu:<version>
  #       all have cloud-init enabled, but images:ubuntu-<version> do not
  #       by default. (FACT CHECK)
  user.user-data: |
    #cloud-config
    # The above comment is strictly necessary! Without it, cloud-init
    #     won't pick up your configuration

    # This just runs `apt update && apt upgrade -y`
    package_upgrade: true

    # These packages will be installed. The packages are referred to by
    #   their name in Ubuntu ppa's, but if you use cloud-init with another
    #   distribution, from my understanding, these should be translated to the
    #   equivalent packages in that distribution.
    packages:
      - fish
      - tree
      - git
      - squashfuse
      - kitty-terminfo

    # These commands will be run (as root). Since we intend to be root
    #     with this profile, this should almost exclusively be fine. If
    #     you need to run a command as a non-root user, you can use `sudo -u <user>`
    runcmd:
      - [chsh, -s, /bin/fish]
      - [snap, install, starship]
      - [snap, install, --channel=latest/edge, snapcraft, --classic]
      # - [snap, set, system, experimental.parallel-instances=true]
      # - [snap, install, --name=snapcraft_6, --channel=6.x/stable, snapcraft, --classic]

description: Snapcraft 7 Build Container

devices:

  # It's convenient to have some basic setup common to all your containers.
  # Be wary of contamination! Half the point of containers is to have a clean environment to test.
  #
  # For my setup, I have a clean version of my configuration files (fish, vim,
  #     git, etc.) in `~/.config/lxd/<profile>` and a working version in
  #     `~/.local/share/lxd/<profile>`. If the working version ever gets too cluttered,
  #     I can just nuke it and replace with the clean copies. Note that I've chosen these
  #     directories arbitrarily.
  dot-config:
    path: /root/.config
    source: /home/jbrock/.local/share/lxd/snapcraft
    type: disk

  # Enable networking using the default LXD bridge lxdbr0
  eth0:
    name: eth0
    network: lxdbr0
    type: nic

  # Define the rootfs, uses the default ZFS pool
  root:
    path: /
    pool: default
    type: disk

  # Bring in sensitive files.
  # For me, this is a tomb volume that contains things like my snapcraft credentials.
  secrets:
    path: /root/secrets
    source: /media/WORK
    type: disk

  # Bring in snaps, and any other projects
  snaps:
    path: /root/lab
    source: /home/jbrock/lab/snaps
    type: disk

  # Bring in ssh keys readonly, to be able to push changes in git
  ssh-config:
    path: /root/.ssh
    readonly: "true"
    source: /home/jbrock/.ssh
    type: disk

name: snapcraft
used_by: []
```

### Profile as a Non-root User
```yaml
config:

  # Note that in this profile uid/gid 1000 is being mapped to 1000
  #     in the container. This is what we want since we'll primarily
  #     be acting as the non-root user created later in the cloud-init
  #     config.
  raw.idmap: both 1000 1000

  user.user-data: |
    #cloud-config
    package_upgrade: true
    packages:
      - fish
      - tree
      - git
      - squashfuse
      - kitty-terminfo
    runcmd:
      - [snap, install, starship]
      - [snap, install, --channel=latest/edge, snapcraft, --classic]
      # - [snap, set, system, experimental.parallel-instances=true]
      # - [snap, install, --name=snapcraft_6, --channel=6.x/stable, snapcraft, --classic]

    # Create a new user.
    # Here we create a new user, set their groups, sudo permissions, and default shell
    users:
      - name: jbrock
        gecos: Joseph Brock
        groups: users, admin
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/fish

description: Snapcraft 7 Build Container

# Everthing here is the same, but we mount to the new user's home directory
devices:
  dot-config:
    path: /home/jbrock/.config
    readonly: "true"
    source: /home/jbrock/.local/share/lxd/build
    type: disk
  eth0:
    name: eth0
    network: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
  secrets:
    path: /home/jbrock/secrets
    source: /media/WORK/
    type: disk
  snaps:
    path: /home/jbrock/lab
    source: /home/jbrock/lab/snaps
    type: disk
  ssh-config:
    path: /home/jbrock/.ssh
    readonly: "true"
    source: /home/jbrock/.ssh/
    type: disk

name: build
used_by: []
```

## Aliases
It can be convenient to have aliases, especially when shelling into a container as a non-root user.
Remember that when you invoke `lxc shell <container>` it's essentially a built-in alias to `lxc exec @ARGS@ -- su`. You can confirm this by running `lxc shell --help`:
```
Description:
  Execute commands in instances

  The command is executed directly using exec, so there is no shell and
  shell patterns (variables, file redirects, ...) won't be understood.
  If you need a shell environment you need to execute the shell
  executable, passing the shell commands as arguments, for example:

    lxc exec <instance> -- sh -c "cd /tmp && pwd"

  Mode defaults to non-interactive, interactive mode is selected if both stdin AND stdout are terminals (stderr is ignored).
 ...
```

By slightly modifying this, we can have an alias that logs us in as the user we created in cloud-init:
```
lxc alias add sh "exec @ARGS@ -- su -l <username>"
```

Now we can get a non-root shell with (for those containers that have a user named `<username>`)
```
lxc sh <container>
```

# To Do
 - [ ] Add specific examples for LXD setups
   - [ ] microk8s in an LXD container
   - [ ] X display in an LXD container
   - [ ] Wayland in an LXD container
