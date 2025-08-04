# 📦 `release` utility

[![Pub Likes](https://img.shields.io/pub/likes/release?style=flat-square)](https://pub.dev/packages/release/score)
[![Pub Points](https://img.shields.io/pub/points/release?style=flat-square)](https://pub.dev/packages/release/score)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](#license)

The `release` utility is, as its name suggests, a small command-line tool that helps you quickly
release your Dart apps.

It takes care of :

* Reading the _pubspec.yaml_ file to find the current version.
* Detecting changes since the last `release` run.
* Bumping the version and version code, including marking breaking changes.
* Writing the changes to the _CHANGELOG.md_ file.
* Updating both _pubspec.yaml_ and _snap/snapcraft.yaml_.
* Committing and pushing the changes.
* Creating a Github release, or just a tag if the release fails.
* Publishing to [pub.dev](https://pub.dev), if no `publish_to: none` is specified in the
  _pubspec.yaml_.

Also : almost everything is configurable.

> [!WARNING]  
> Currently, `release` has only been tested on Windows. Feel free to try it on other platforms and
> share your feedback !

## Getting Started

### Installation

For most users, simply run the following commands :

```shell
dart pub add dev:release
dart pub get
```

> [!NOTE]  
> You can add it as a regular dependency by removing the `dev:` prefix. This will allow you to use
> the [`Release`](https://github.com/Skyost/DartRelease/blob/main/lib/src/release.dart) class
> directly in your code.

### Usage

It's as simple as :

```shell
dart run release
```

The utility will guide you through the release process. Note that in order to generate your
_CHANGELOG.md_ file, `release` requires your commits to follow the
[Conventional Commits](https://conventionalcommits.org) format.

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
    # Entries are processed using the Liquid template engine.
    entry:
      title: '## v{{ version }}' # This is the default.
      header: 'Released on {{ date | date: "MMMM d, yyyy" }}.' # This is the default.
      item: '* **{% if breaking %}BREAKING {% endif %}{{ type | upcase }}**: {{ description }} ({% if repo %}[#{{ hash }}](https://github.com/{{ repo }}/commit/{{ hash }}){% else %}#{{ hash }}{% endif %})' # This is the default.
    git:
      github: https://github.com/me/my_app # Alternative to top-level `repository`.
      newVersionCommitMessage: 'chore(version): Updated version and changelog.' # This is the default.
      remote: 'main' # This is the default.
```

### Setting up Github Releases

To enable Github releases, go to
[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)
to create a new fine-grained personal access token.

* **Token name**: Choose any name you like.
* **Description**: Optional.
* **Expiration date**: Set as preferred.

In the **Repository access** section, select **Only select repositories**, then choose your app's
repository.

In the **Permissions** section :

* Click **Add permissions**.
* Under **Contents** :
    * Set **Contents** to _Read and write_.
    * Set **Metadata** to _Read-only_.

_[Here](https://github.com/user-attachments/assets/2e2d49cb-f8f7-400f-8b1d-928c8fc78adc) is a
screenshot of my setup for the `release` utility._

Once done, click **Generate token**. Then create a _.env_ file at the root of your project folder
and add your Github token :

```env
GITHUB_PAT=github_pat_...
```

> [!CAUTION]  
> This token should **never be shared**. Be sure to exclude the `.env` file from version control (
> e.g., by adding it to your `.gitignore`).

### Example

This utility is already in use in some of my apps and projects. Feel free to check out their
_CHANGELOG.md_, _pubspec.yaml_, and release pages :

* [Open Authenticator](https://github.com/Skyost/OpenAuthenticator)
* [Scriny](https://github.com/Skyost/Scriny)
* [Beerstory](https://github.com/Skyost/Beerstory)

## License

This project is licensed under
the [MIT License](https://github.com/Skyost/DartRelease/blob/main/LICENSE).

## Contributions

There are many ways to contribute to this project :

* [Fork it](https://github.com/Skyost/DartRelease/fork) on Github.
* [Submit an issue](https://github.com/Skyost/DartRelease/issues/new/choose) for a feature request
  or bug report.
* [Donate](https://paypal.me/Skyost) to support the developer.
