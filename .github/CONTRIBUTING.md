# Contributing

This repository builds the standard OpenWebRX+ and SoftMBE Docker images and
maintains their Docker Compose deployment documentation.

## Before making a change

For usage questions and upstream projects, see [Support](SUPPORT.md). Report image
or build problems using the bug report form, and describe proposed features using
the feature request form. Search existing issues before opening a new one.

Keep pull requests focused on one problem. Explain the resulting behavior and
include enough validation for another contributor to assess the change.

## Repository layout

- [README](../README.md): image builds and native package information.
- [docker.md](../docker.md): primary installation and configuration guide.
- [compose.yaml](../compose.yaml) and [.env.example](../.env.example): maintained deployment template.
- [buildfiles](../buildfiles): Dockerfiles, build scripts and image assets.
- [Documentation workflow](workflows/validate-docs.yml): automated installation checks.

Docker Compose is the supported installation method. Keep examples in the
deployment template and link to it from documentation rather than maintaining
another full copy of its YAML.

## Local checks

Use Docker with the Compose plugin and Python 3 for the checks used by CI. Validate
both image selections without starting containers or accessing SDR hardware:

```sh
for image in slechev/openwebrxplus:latest slechev/openwebrxplus-softmbe:latest; do
  OPENWEBRX_ADMIN_PASSWORD=ci-validation-only OWRX_IMAGE="$image" \
    docker compose --env-file .env.example config --quiet || exit 1
done
git diff --check
```

The password above is a dummy value for configuration validation only. Do not
commit a real `.env` file, passwords or tokens.

For changed shell scripts, run `bash -n path/to/script.sh` and appropriate checks
for the behavior you changed. For build changes, document the build command,
architecture, image variant and result; the documentation workflow does not build
images or test reception.

## Automated checks and pull requests

The installation documentation workflow runs on pushes and pull requests. It
validates both Compose image variants, rejects an empty initial admin password,
checks local documentation links and section anchors, and checks shell example
syntax. Dependabot proposes weekly GitHub Actions updates for review.

Use the PR template to describe the change, its reason, validation and user impact.
Update the guide and deployment defaults together when changing configuration.
Describe hardware-dependent checks you could not perform instead of reporting
them as tested.
