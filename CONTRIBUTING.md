# Contributing

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

## Contributing

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
4. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
5. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
6. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!

## Development

To develop and run tests against Conjur OSS, use the `start` and `stop` scripts in the `dev` folder. The start script brings up a Conjur OSS (and Postgres database), CLI container, and a "work" container, with the gem code mounted into the working directory.

### Starting a Shell

To begin:

```sh
$ cd dev
$ ./start
...
root@9df0ac10ada2:/src/conjur-api#
```

You'll be dropped into development container upon completion. From there, install the development gems:

```sh
root@9df0ac10ada2:/src/conjur-api# bundle
```

#### Running Tests

Tests can be run with:

```sh
root@9df0ac10ada2:/src/conjur-api# bundle exec cucumber features
root@9df0ac10ada2:/src/conjur-api# bundle exec rspec
```

Note: At the moment some of the cucumber tests are failing when run in the development container.
You can use the CI script, `test.sh` to run the full test suite instead.

#### Stopping & Environment Cleanup

Once you're done, exit the shell, and stop the containers:

```sh
root@9df0ac10ada2:/src/conjur-api# exit
$ ./stop
```

### Demos

```sh-session
bundle exec ./example/demo.rb <admin-api-key>
```

### Stopping

To bring it down, run:

```sh-session
docker compose down
```

## Releasing

### Update the version and changelog

1. Create a new branch for the version bump.
1. Based on the changelog content, determine the new version number and update.
1. Review the [changelog](CHANGELOG.md) to make sure all relevant changes since
   the last release have been captured. You may find it helpful to look at the
   list of commits since the last release.

   This is also a good time to make sure all entries conform to our
   [changelog guidelines](https://github.com/cyberark/community/blob/main/Conjur/CONTRIBUTING.md#changelog-guidelines).
1. Commit these changes - `Bump version to x.y.z` is an acceptable commit message - and open a PR
   for review. Your PR should include updates to `CHANGELOG.md`.

### Release and Promote

1. Jenkins build parameters can be utilized to release and promote successful builds.
1. Merging into main/master branches will automatically trigger a release.
1. Reference the [internal automated release doc](https://github.com/conjurinc/docs/blob/master/reference/infrastructure/automated_releases.md#release-and-promotion-process)
   for releasing and promoting.
