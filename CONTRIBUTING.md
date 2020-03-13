# Contributing

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

## Contributing

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
3. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
4. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
5. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!


## Development (V5)
To develop and run tests against Conjur V5, use the `start` and `stop` scripts in the `dev` folder. The start script brings up an open source Conjur (and Postgres database), CLI container, and a "work" container, with the gem code mounted into the working directory.

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
*NOTE*: There are some existing challenges around running tests from the development console.  For now, run tests
by using the `./test.sh` script utilized for Jenkins Pipelines.

<!--
Commented out until I can get tests running locally

Tests can be run with:
```sh
root@9df0ac10ada2:/src/conjur-api# bundle exec cucumber features
root@9df0ac10ada2:/src/conjur-api# bundle exec rspec
```
-->

#### Stopping & Environment Cleanup
Once you're done, exit the shell, and stop the containers:

```sh
root@9df0ac10ada2:/src/conjur-api# exit
$ ./stop
```

## Development (V4)

The file `docker-compose.yml` is a self-contained development environment for the project.

### Starting

To bring it up, run:

```sh-session
$ docker-compose build
$ docker-compose up -d pg conjur_4 conjur_5
```

Then configure the v4 and v5 servers:

```sh-session
$ ./ci/configure_v4.sh
...
$ ./ci/configure_v5.sh
...
```

### Using

Obtain the API key for the v5 admin user:

```
$ docker-compose exec conjur_5 rake 'role:retrieve-key[cucumber:user:admin]'
3aezp05q3wkem3hmegymwzz8wh3bs3dr6xx3y3m2q41k5ymebkc
```

The password of the v4 admin user is "secret".

Now you can run the client `dev` container:

```sh-session
$ docker-compose run --rm dev
```

This gives you a shell session with `conjur_4` and `conjur_5` available as linked containers.

### Demos

For a v5 demo, run:

```sh-session
$ bundle exec ./example/demo_v5.rb <admin-api-key>
```

For a v4 demo, run:

```sh-session
$ bundle exec ./example/demo_v4.rb
```

### Stopping

To bring it down, run:

```sh-session
$ docker-compose down
```

## Releasing

Releasing a new version of this Gem involves a two step process:
1. Tag and Release (using `bin/release`)
2. Approving the push to RubyGems in Jenkins

### Step 1: Tag and Release

First, update the following files:

- The version file (`lib/conjur-api/version.rb`) has been updated with an appropriate Semantic version number.
- The `CHANGELOG.md` file has been updated to reflect the release version and appropriate release notes.

Next, save -- but do not commit -- the changes above.

Finally, when you're ready to release, run the following:

```sh
$ bin/release
```

### Step 2: Approve the push to RubyGems in Jenkins

- Navigate to Jenkins: https://jenkins.conjur.net/job/cyberark--conjur-api-ruby/job/master/.
- Once the pipeline reaches the `Publish to RubyGems?` stage, click the blue box, and then click `Logs`.
- Open the confirmation step (`Wait for interactive input -- Publish to RubyGems?`), and click `Proceed`. Nothing appears to happen, but the "Publish" stage will be run.
- Finally, verify that the new library is present in RubyGems: https://rubygems.org/gems/conjur-api

The release is now complete.
