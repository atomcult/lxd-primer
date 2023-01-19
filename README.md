# LXD: An Opinionated Primer

> **NOTICE**: I've moved away from cloud-init to the lxd-init script provided
> in this repository. You can still find the old version of the documentation
> on the [cloud-init branch](https://github.com/atomcult/lxd-primer/tree/cloud-init).


* [Getting Started](#getting-started)
* [Using lxd-init](#using-lxd-init)
* [Remotes](#remotes)
* [Profiles](#profiles)
  * [Basics](#basics)
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

## Using lxd-init
```sh
# Put the script somewhere in your path
ln -s "$PWD/lxd-init $HOME/.local/bin"

# Edit the default profile to meet your needs and import
lxc profile edit default < profiles/default.yaml

# Launch a container with the default profile
lxc launch ubuntu:20.04 <my-container>

# Initialize
lxd-init --root --config @/config --script @/scripts/ubuntu.sh --login <my-container>
```
Let's break that last command down into components to see what it's doing.
`--root` tells the script that you'd like to run as root in the container. This makes sure that your current user is mapped to root inside the container. This mostly has effects things like file ownership and permissions. Any files you create within the container will actually be owned by your UID outside the container. The alternative to this is to use the `--user` or `--username <name>` flags which optionally create or use an already existing user within the container (and perform the aforementioned mapping). A container that's already been initialized can have its mapping switched at any time with any of these flags.

The `--config <dir>` flag takes a directory and simply copies all of the contents of that directory to the home of the currently configured user (as determined by the user mapping). You'll notice that in the example, the path given starts with `@/`. This is simply a shorthand for the real directory (meaning the directory that contains the actual script, not just a symlink to it) that the script resides in.

As you might guess, `--script <path>` indicates a script that you'd like to run within the container. As of this writing, this script **must** be sh/dash compliant, as the script is simply piped into that container's version of sh. This has a great deal more flexibility than other instantiation methods, like cloud-init, because you can use logic to determine what actions should be taken. In the `ubuntu.sh` script, for example, it determines what packages to install based on the version of Ubuntu. There's also a good opportunity for script composition, since you can simple source other scripts you have written.

Finally, `--login` just says to open up a shell as the configured user once all the initialization is done.

This script is under continual development, so check back to see what new features have been added. If you have a feature request, feel free to open an issue or PR!

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

You can check all the remotes that are set up with
```sh
lxc remote ls
```

## Profiles

Profiles allow you to set up a container with a default set of instance configuration values as if you had set them manually with `lxd config ...`. As such, any configuration that can be set through the `lxd config` facilities also works with profiles.

For more information about configuring profiles, refer to the following documents. There are *many, many* things that can be configured that are not touched upon in this primer.
 - [LXD Profile Configuration Docs](https://linuxcontainers.org/lxd/docs/master/profiles/)
 - [LXD Instance Configuration Docs](https://linuxcontainers.org/lxd/docs/master/instances/)

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

or better yet, import a stock config that you maintain in, e.g., a git repo:
```
lxc profile edit <profile> < <profile.yaml>
```

You can verify your work with
```
lxc profile show <profile>
```

The profile can now be used when launching an instance (potentially in combination with others):
```
lxc launch ubuntu:22.04 -p <profile> [-p <profile-2> ...] <container-name>
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

By slightly modifying this, we can have an alias that logs us in as a non-root user:
```
lxc alias add sh "exec @ARGS@ -- su -l <username>"
```

Now we can get a non-root shell with (for those containers that have a user named `<username>`)
```
lxc sh <container>
```

**Note**: In Ubuntu LXD images there's an `ubuntu` user by default, so you shouldn't have to create a user to be non-root.

# To Do
 - [ ] Add specific examples for LXD setups
   - [ ] microk8s in an LXD container
   - [ ] X display in an LXD container
   - [ ] Wayland in an LXD container
