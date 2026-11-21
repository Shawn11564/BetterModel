# Our BetterModel fork

This is the dungeons server's copy of [toxicity188/BetterModel](https://github.com/toxicity188/BetterModel).

## Branches

- Upstream is tracked through the `upstream` remote (`git remote add upstream
  https://github.com/toxicity188/BetterModel.git`), not by syncing this fork's `v3`. Leave `v3`
  alone and don't press "Sync fork": a push to `v3` here starts upstream's publishing workflows
  (see CI below).
- `dungeons` is our changes, as a few commits on top of upstream's latest **official release**
  tag (currently 3.7.1). Never upstream's unreleased `v3` commits: the release workflow refuses
  to build those. Commit fixes and features here.

Keep the changes small. Offer anything general back upstream as a pull request: every change
upstream accepts is one we stop carrying.

## Releasing

Tags are named `<upstream release>-dungeons.<n>`. Pushing one runs
`.github/workflows/dungeons-release.yml`. It first runs `.github/check-dungeons-base.sh`, which
fails unless the branch sits exactly on that upstream release (no later upstream commits), then
builds the plugin with the tag as its version and attaches `bettermodel-<tag>-paper.jar` plus the
API jars to a GitHub Release. The release notes list our changes.

```sh
git fetch upstream --tags
bash .github/check-dungeons-base.sh 3.7.1-dungeons.3 HEAD upstream/v3   # the same check, locally
git tag 3.7.1-dungeons.3 && git push origin 3.7.1-dungeons.3
```

Then set `betterModelRelease=3.7.1-dungeons.3` in the dungeons project's `gradle.properties` and
run `python scripts/boss-smoke.py` there.

The dungeons project compiles against upstream's API from Maven Central (`betterModelVersion`).
If a change here alters the API, wire the API jars from the release into its build.

## Upgrading to a new upstream release

When upstream publishes a release (say 3.7.2), move our commits from the old release onto it:

```sh
git fetch upstream --tags
git rebase --onto 3.7.2 3.7.1 dungeons     # old release -> new release
git push --force-with-lease origin dungeons
git tag 3.7.2-dungeons.1 && git push origin 3.7.2-dungeons.1
```

Then in the dungeons project set `betterModelRelease=3.7.2-dungeons.1` and `betterModelVersion=3.7.2`
(the API our plugins compile against, on Maven Central), and run its smoke test.

## CI

Upstream's `package.yml`, `publish.yml` and `release.yml` publish to Hangar, Modrinth, Maven
Central and GitHub Packages. They only start on a push to `v3`/`master`/`v2` or a release
published by hand (our workflow's release is made with `GITHUB_TOKEN`, which starts no
workflows), so normally they never run here. GitHub can't disable a workflow before its first
run; if one ever runs, disable all three:

```sh
for w in package.yml publish.yml release.yml; do gh workflow disable $w -R Shawn11564/BetterModel; done
```

Only `dungeons-release.yml` (and `pr-test.yml`, on pull requests) should run here.

Building locally: `gradlew :platform:bettermodel-paper:shadowJar -Pproject_version=<version>`.
The first build sets up a Minecraft server for each of the 8 supported versions, which takes a
while and several GB.
