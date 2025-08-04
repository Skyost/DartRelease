# 📦 `release` utility

[![Pub Likes](https://img.shields.io/pub/likes/release?style=flat-square)](https://pub.dev/packages/release/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/release?style=flat-square)](https://pub.dev/packages/release/score)
[![Pub Points](https://img.shields.io/pub/points/release?style=flat-square)](https://pub.dev/packages/release/score)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](#License)

`release` utility is, as its name may suggest, a small command line utility that helps you quickly
releasing your Darts apps.

It takes care of :

* Reading the _pubspec.yaml_ file to find the current version.
* Finding the changes since the last `release` run.
* Bumping the version and the version code, marking breaking changes.
* Writing the changes in the _CHANGELOG.md_ file.
* Updating both _pubspec.yaml_ and _snap/snapcraft.yaml_ files.
* Committing and pushing the changes.
* Creating a Github release, or just a tag if the previous step has failed.
* Publishing the [pub.dev](https://pub.dev) package, if no `publish_to: none` is specified in the
  _pubspec.yaml_ file.

Also : almost everything is configurable.

> [!WARNING]  
> Currently, `release` has only been tested on Windows. Feel free to test it on other platforms
> and to give your feedback !

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
_CHANGELOG.md_ file,
`release` needs your commits to be formatted according
to [conventional commits](https://conventionalcommits.org).

### Configuration

You can configure the `release` utility directly in your _pubspec.yaml_ file.
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

### Setup Github releases

You have to go
to [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)
in order to create a new fine-grained token.

* **Token name** : put your token name here.
* **Description** : put anything you want here.
* **Expiration date** : enter any expiration date you want.

In the **Repository access** section, tick **Only select repositories** and then choose your app
repository.

Then, in the **Permissions** section, click on **Add permissions**, select **Contents** and then,
adjust the accesses like this :

* **Contents** : must be set to _Read and write_.
* **Metadata** : must be set to _Read only_.

Here's a screenshot of my setup for the `release` utility :

<img src="https://github.com/user-attachments/assets/2e2d49cb-f8f7-400f-8b1d-928c8fc78adc" height="500" alt="Screenshot">

Once done, click on **Generate token**. Then, all you have to do it to create a _.env_ file,
at the root of your project folder containing your Github token :

```env
GITHUB_PAT=github_pat_...
```

> [!CAUTION]
> This token should not be shared with anyone. In particular, the _.env_ file should not be
> version controlled (ie. put it in _.gitignore_).

### Example

This utility is used in some of my apps and projects. Feel free to check their _CHANGELOG.md_,
their _pubspec.yaml_, their releases page, etc.

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
