# LXD: An Opinionated Primer

* [Getting Started](#getting-started)
* [Remotes](#remotes)
* [Profiles](#profiles)
  * [Basics](#basics)
  * [Examples (Annotated)](#examples-annotated)
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

## Profiles

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

If your profile includes cloud-init, it will take extra time for everything to be setup, since it is run after the container is initialized. You can check the console output with the following command:
```
lxc console <container-name>
```

Once you see the message
```
[  OK  ] Finished Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.
```
cloud-init has finished setting up. You can exit with `^a q`.

### Examples (Annotated)
 - [Profile as Root](https://github.com/atomcult/lxd-primer/blob/main/profiles/00_snapcraft.yaml)
 - [Profile as a Non-root User](https://github.com/atomcult/lxd-primer/blob/main/profiles/01_nonroot.yaml)

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
