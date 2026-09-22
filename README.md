# os161
Environment and utilities for running OS/161.

The original `Dockerfile` is adapted from the Docker instructions for the [UBC ECE OS/161 course website](https://people.ece.ubc.ca/~os161/os161-site/install-docker.html). The image has been modified to use Debian 11's EOL image and update its source lists.

`.gdbinit` is adapted from `kern/gdbscripts/array` in the OS/161 source code.

## Usage

The environment can be entered with the CLI:

```bash
./start
```