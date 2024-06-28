## What

_A small collection of minimal scripts to help in everyday tasks developing [Gutenberg](https://github.com/WordPress/gutenberg), like debugging or quick branch switches. They are meant to compose nicely together or within custom scripts._

## Installation

Drop or symlink this repository into a directory called `scripts` at the root of your Gutenberg repository.

### Requirements

* [`gh`](https://github.com/cli/cli), GitHub's CLI tool
* An implementation of `unzip` compatible with mine :) (with options `-q` and `-o`)

## Scripts

### `get-plugin-zip`

* Attempts to download a pre-built ZIP file of the Gutenberg plugin from Gutenberg's GitHub workflows
* Downloads into the current directory under the name `gutenberg.zip`
* Returns 0 if successful, 1 otherwise
* Defaults to fetching the file corresponding to the locally checked out commit
* Can be changed via the environment variable $REVISION, e.g. `REVISION=1234 scripts/get-plugin-zip`

Example usage:

```sh
$ cd ~/repositories/gutenberg
$ git checkout trunk
$ (scripts/get-plugin-zip && unzip -t gutenberg.zip) || echo "no ZIP file available"
```

### `load-build`

* Attempts to speed up the build process by fetching a ZIP file from GitHub (see `get-plugin-zip`) and unzipping it
* Falls back to `npm ci && npm run build` if no corresponding ZIP artifact was found

Example usage:

```sh
$ gh pr checkout 1234  # Grab a recent pull request
$ scripts/load-build   # Load it without 'npm run build'
```

### `load-and-bisect`

* Can be used to greatly speed up a git-bisect task by using its sibling `load-build`
  - Where a full `npm ci && npm run build` cycle can take 5 minutes, loading from a ZIP file takes about 5 seconds
* At each bisection step:
  - The user can go manually test Gutenberg as soon as the console reads "Build ready"
  - The tool then prompts the user for feedback to mark the revision as _good_ or _bad_
  - Rinse and repeat

Example usage:

```sh
$ git bisect start
$ git bisect bad trunk
$ git bisect good v17.0.0
$ git bisect run scripts/load-and-bisect

Bisecting: 6 revisions left to test after this (roughly 3 steps)
[394abb3cec24e48011d3aebfabb9ed180e7a0d77] Update: Remove keyCode usage from dataviews package. (#60585)
running  'scripts/load-and-bisect'
Build ready.
git bisect [good/bad/old/new]:
```
