# nstcli

nstcli is a command-line tool designed for managing the agent client efficiently.


## Basic Commands

### Agent Management

#### Start the Agent
```sh
nstcli start
```
Starts the agent service.

#### Stop the Agent
```sh
nstcli quit
```
Stops the agent service.

#### Upgrade the Agent
```sh
nstcli upgrade
```
Upgrades the agent to the latest version.

#### Get Agent Information
```sh
nstcli info
```
Retrieves the agent's status and configuration details.

---

### Profile Management

#### Create a Profile
```sh
nstcli create [name] [options]
```
Creates a new profile in `headless` mode by default.

**Options:**
- `-k, --kernelMilestone` Specify the kernel version (default: latest local version)
- `-p, --proxy` Specify a proxy

#### Run a Profile
```sh
nstcli run [profile...]
```
Runs the specified profile(s).

**Options:**
- `-f, --force` Force start the profile

#### Stop a Profile
```sh
nstcli stop [profile...]
```
Stops the specified profile(s).

**Options:**
- `-a, --all` Stop all running profiles

#### List Active Profiles
```sh
nstcli ps [options]
```
Displays running profiles with additional filtering options.

**Options:**
- `-p, --page` Pagination parameter
- `-s, --search` Search criteria
- `-g, --group` Group results

#### Inspect a Profile
```sh
nstcli inspect [profile]
```
Retrieves detailed information about a specific profile.

---

### Kernel Management

#### List Kernel Versions
```sh
nstcli kernel ps [options]
```
Lists available kernel versions.

**Options:**
- `-a, --all` Show all released versions

#### Update Kernel
```sh
nstcli kernel update [kernelMilestone]
```
Updates to the latest released kernel version.

#### Remove a Kernel Version
```sh
nstcli kernel rm [kernelMilestone]
```
Removes a specific kernel version.

#### Install a Kernel Version
```sh
nstcli kernel install [kernelMilestone]
```
Installs the specified kernel version.
