import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/processes/write_changelog.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/git.dart';
import 'package:release/src/utils/version.dart';

/// A process that asks the user to create a Github release.
class CreateGithubReleaseProcess with ReleaseProcess {
  /// Creates a new [CreateGithubReleaseProcess] instance.
  const CreateGithubReleaseProcess();

  @override
  Future<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) async {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (pubspecContent == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }

    bool createRelease = cmd.askQuestion('Do you want to create a Github release ?');
    if (!createRelease) {
      return const ReleaseProcessResultCancelled();
    }

    String? repository = pubspecContent.config.githubRepository;
    if (repository == null) {
      return ReleaseProcessResultError(error: 'Cannot find the Github repository in the pubspec.');
    }

    DotEnv env = DotEnv()..load();
    String token = env.getOrElse('GITHUB_PAT', () => '');
    if (token.isEmpty) {
      return ReleaseProcessResultError(error: 'Cannot find GITHUB_PAT in .env.');
    }

    stdout.writeln('Creating a release on Github...');
    http.Response response = await http.post(
      Uri(
        scheme: 'https',
        host: 'api.github.com',
        path: 'repos/$repository/releases',
      ),
      headers: {
        HttpHeaders.acceptHeader: 'application/vnd.github+json',
        HttpHeaders.authorizationHeader: 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      body: jsonEncode({
        'tag_name': newVersion.version.buildName(includeBuild: false, includePreRelease: false),
        'name': 'v${newVersion.version.buildName(includeBuild: false, includePreRelease: false)}',
        'body': findValue<MarkdownEntryContent>(previousValues)?.content ?? '',
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      stdout.writeln('Done.');
      stdout.writeln('Fetching tags...');
      Git git = Git(cmd: cmd);
      await Future.delayed(const Duration(seconds: 1));
      bool fetchResult = await git.fetch(['--tags']);
      stdout.writeln('Done.');
      return ReleaseProcessResultSuccess(
        value: GithubReleaseCreated(
          fetchResult: fetchResult,
        ),
      );
    } else {
      return ReleaseProcessResultError(error: 'An error occurred (status code : ${response.statusCode}).');
    }
  }
}

/// The result of the [CreateGithubReleaseProcess].
class GithubReleaseCreated {
  /// Whether the tags were fetched.
  final bool fetchResult;

  /// Creates a new [GithubReleaseCreated] instance.
  const GithubReleaseCreated({
    required this.fetchResult,
  });
}
