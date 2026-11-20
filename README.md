# compose-all

Bash tools for running Docker Compose commands across multiple stacks and for working with a single Compose project through optional aliases.

## Requirements

- Bash, Docker Engine and the Docker Compose plugin (`docker compose`), with access to the daemon and stacks. `update` requires a Compose version that supports `up --wait`.
- `tmux` and an interactive terminal for `-p` and `update`.
- Common Unix utilities, including `awk`, `date`, `mktemp`, `sleep`, `tail`, and `tee`.
- Write permission to install the script in `/usr/local/bin`.

## Installation

From a checkout of the desired version:

```bash
sudo install -m 0755 compose-all /usr/local/bin/compose-all
mkdir -p "$HOME/.docker-tools"
install -m 0644 compose-all.conf.sample "$HOME/.docker-tools/compose-all.conf.sample"
install -m 0644 aliases.bash "$HOME/.docker-tools/aliases.bash"
```

Place `.docker-tools` in the **home directory of the user running the script**. For example, when running with `sudo` and `HOME=/root`, the files must be in `/root/.docker-tools`. The `sudo` configuration can change `HOME`: check its value in the actual environment. The configuration path is also passed to parallel processes.

Create the configuration only if it does not already exist, then customize it:

```bash
cp -i "$HOME/.docker-tools/compose-all.conf.sample" "$HOME/.docker-tools/compose-all.conf"
```

The configuration is Bash code executed with the script's privileges: protect the file and its parent directories from unauthorized changes, particularly when using `sudo`. Access to the Docker daemon may also grant elevated privileges.

To enable the optional aliases in interactive Bash sessions, add this to `~/.bashrc` manually:

```bash
source "$HOME/.docker-tools/aliases.bash"
```

Then reopen the shell or reload the file. Installation does not modify `.bashrc`. The aliases operate on the Compose project in the current directory; `dk-shell` lets you choose a container when there is more than one. `dk-upgrade` pulls, builds and restarts the project and suggests a global cleanup without executing it.

## Configuration

In `~/.docker-tools/compose-all.conf`, set a base directory and the stack subdirectories in order:

```bash
COMPOSE_BASE_DIR=/path/to/stacks
SERVIZI=(database application)
COMPOSE_UPDATE_WATCH_SECONDS=10
```

The sample uses `/root/docker` as an example: replace it if needed. Each stack must be accessible as `$COMPOSE_BASE_DIR/$servizio` and contain a configuration recognized by Docker Compose. Parallel processes also read the configuration file.

## Usage

```bash
compose-all ps
compose-all -r down
compose-all -p pull
compose-all update
```

Commands other than `update`, together with their arguments, are passed to `docker compose` for each stack. Execution is sequential and stops at the first error; `-r` reverses the order. `-p` runs stacks in parallel in tmux panes: it does not guarantee order and is unsuitable for commands requiring interactive input. Logs remain in the indicated temporary directory and must be removed manually.

At the end, an indicative list shows Compose projects with active containers whose directories do not match configured stacks. Stopped stacks do not appear; errors in this check do not change the result of the main command.

### Update

`compose-all update` accepts no options or arguments. It checks the stack configurations, runs `pull` and `build --pull` in parallel, then runs `up -d --wait` in order. It watches containers and logs for at least `COMPOSE_UPDATE_WATCH_SECONDS` seconds, or 10 if the variable is absent; it must be a positive integer. The sequence stops on errors, new restarts, or unacceptable states and health checks. Containers that exit with code zero are allowed.

**Warning:** after successful checks, `update` runs `docker system prune -af` across the entire node, including resources unrelated to the configured stacks. It can remove images useful for rollback, stopped containers, and unused cache; it does not remove volumes. Observation detects only immediate problems and does not guarantee future operation. There is no automatic rollback: some stacks may already be updated if an error occurs. Leaving tmux before completion interrupts the sequence, but commands already started may continue. Logs remain in the indicated locations.

## Versions and releases

The project uses [Semantic Versioning](https://semver.org/) and Conventional Commits as described in [CONTRIBUTING.md](CONTRIBUTING.md). Each stable release has a full tag, for example `v1.0.0`; `v1` is a moving tag pointing to the latest published release of the same major version. Full tags must not be moved. The initial version remains to be decided by the maintainers.

The project is distributed under the [MIT License](LICENSE).

To install a major version, select the `v1` tag in a checkout or retrieve the three files `compose-all`, `compose-all.conf.sample`, and `aliases.bash` from that ref. A later installation may obtain a newer compatible release; use a full tag or commit for reproducibility. Verify file provenance and integrity before execution. The actual configuration file is not part of the distribution and must not be overwritten.

Release procedure for a maintainer, after review and verification:

1. Assess the included changes and choose the next SemVer version; prepare release notes.
2. On the approved commit, create the full tag, for example `git tag -a v1.0.0 -m 'v1.0.0'`, and publish it with `git push origin v1.0.0`.
3. Publish the release on the Git hosting service with the notes and the full tag. Only after success, update `v1` to the same commit (`git tag -f v1 v1.0.0`) and publish the moving tag with `git push --force origin refs/tags/v1`. Force is limited to the moving tag; coordinate maintainers to avoid concurrent updates.
4. Verify that the full tag, release, and moving tag point to the intended commit. Do not move an already published full tag; correct mistakes with a new release.
