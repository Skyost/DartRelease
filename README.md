# 📦 `release` utility

[![Pub Likes](https://img.shields.io/pub/likes/release?style=flat-square)](https://pub.dev/packages/release/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/release?style=flat-square)](https://pub.dev/packages/release/score)
[![Pub Points](https://img.shields.io/pub/points/release?style=flat-square)](https://pub.dev/packages/release/score)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](#License)

`release` utility is, as its name may suggest, a small command line utility that helps you quickly
releasing your Darts apps.

It takes care of :

* Reading the pubspec.yaml file to find the current version.
* Finding the changes since the last `release` run.
* Bumping the version and the version code, marking breaking changes.
* Writing the changes in the CHANGELOG.md file.
* Updating both pubspec.yaml and snap/snapcraft.yaml files.
* Committing and pushing the changes.
* Creating a Github release, or just a tag if the previous step has failed.
* Publishing the [pub.dev](https://pub.dev) package, if no `publish_to: none` is specified in the
  pubspec.yaml file.

Also : almost everything is configurable.

## Getting started

### Installation

For most users, you only have to run the following commands :

```shell
dart pub add dev:release
dart pub get
```

> [!NOTE]
> It can be added as a regular dependency by removing the `dev:` prefix. You'll be able to use
> the [`Release`](https://github.com/Skyost/DartRelease/blob/main/lib/src/release.dart) class in
> your code.

### Usage

It's simple as :

```shell
dart run release
```

The utility will guide you through the release process. Note that, in order to generate your
CHANGELOG.md file,
`release` needs your commits to be formatted according
to [conventional commits](https://conventionalcommits.org).

### Configuration

You can configure the `release` utility directly in your `pubspec.yaml` file.
Here's an example :

```yaml
name: my_app
description: my_app_description
version: 0.0.1
repository: https://github.com/me/my_app

# Other values, like dependencies and dev dependencies.

# See https://pub.dev/documentation/release/latest/release/ReleaseConfig-class.html for more details.
release:
  changelog:
    header: '# 📰 my_app changelog'
    defaultIgnoredScopes: [ 'docs', 'version', 'deps' ] # This is the default.
    # Entries are processed using Liquid template engine.
    entry:
      title: '## v{{ version }}' # This is the default.
      header: 'Released on {{ date | date: "MMMM d, yyyy" }}.' # This is the default.
      item: '* **{% if breaking %}BREAKING {% endif %}{{ type | upcase }}**: {{ description }} ({% if repo %}[#{{ hash }}](https://github.com/{{ repo }}/commit/{{ hash }}){% else %}#{{ hash }}{% endif %})' # This is the default.
    git:
      github: https://github.com/me/my_app # Alternative to top-level `repository`.
      newVersionCommitMessage: 'chore(version): Updated version and changelog.' # This is the default.
      remote: 'main' # This is the default.
```

### Example

This utility is used in some of my apps and projects. Feel free to check their CHANGELOG.md,
their pubspec.yaml, their releases page, etc.

* [Open Authenticator](https://github.com/Skyost/OpenAuthenticator)
* [Scriny](https://github.com/Skyost/Scriny)
* [Beerstory](https://github.com/Skyost/Beerstory)

## License

This project is licensed under
the [MIT License](https://github.com/Skyost/DartRelease/blob/main/LICENSE).

## Contributions

There are many ways you can contribute to this project :

* [Fork it](https://github.com/Skyost/DartRelease/fork) on GitHub.
* [Submit an issue](https://github.com/Skyost/DartRelease/issues/new/choose) for a feature request
  or bug report.
* [Donate](https://paypal.me/Skyost) to support the developer.
