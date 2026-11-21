# Our BetterModel fork

This is the dungeons server's copy of [toxicity188/BetterModel](https://github.com/toxicity188/BetterModel).

## Branches

- Upstream is tracked through the `upstream` remote (`git remote add upstream
  https://github.com/toxicity188/BetterModel.git`), not by syncing this fork's `v3`. Leave `v3`
  alone and don't press "Sync fork": a push to `v3` here starts upstream's publishing workflows
  (see CI below).
- `dungeons` is our changes, as a few commits on top of upstream's latest `v3` (currently
  c84b7ec4, 3.7.2 in development, after 3.7.1). Commit fixes and features here. To stay on
  released code only, rebase onto a release tag instead (`git rebase --onto 3.7.2 upstream/v3
  dungeons` would move onto the 3.7.2 release).

Keep the changes small. Offer anything general back upstream as a pull request: every change
upstream accepts is one we stop carrying.

## Releasing

Tags are named `<project_version>-dungeons.<n>`, where `project_version` is upstream's in
`gradle.properties` at the commit we're built on (the workflow refuses any other tag). Pushing one
runs `.github/workflows/dungeons-release.yml`, which builds the plugin with that version and
attaches `bettermodel-<tag>-paper.jar` plus the API jars to a GitHub Release. The release notes
name the upstream commit it's built on and list our changes.

```sh
git tag 3.7.2-dungeons.2 && git push origin 3.7.2-dungeons.2
```

Then set `betterModelRelease=3.7.2-dungeons.2` in the dungeons project's `gradle.properties` and
run `python scripts/boss-smoke.py` there.

A `3.7.2-dungeons.<n>` built before upstream releases 3.7.2 is development code; its release
notes say so.

The dungeons project compiles against upstream's API from Maven Central (`betterModelVersion`).
If a change here alters the API, wire the API jars from the release into its build.

## Pulling in upstream's new commits

```sh
git fetch upstream --tags
git rebase upstream/v3                     # replays only our commits onto upstream's latest
git push --force-with-lease origin dungeons
git tag <project_version>-dungeons.<n> && git push origin <that tag>
```

Then bump `betterModelRelease` in the dungeons project and run its smoke test. If upstream's
public API changed in a way our plugins use, bump `betterModelVersion` there too (once that
version is on Maven Central) or wire in the API jars from our release.

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
