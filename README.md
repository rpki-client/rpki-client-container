# Container image for rpki-client

## About

Source files and build instructions for an [OCI](https://opencontainers.org/) image (compatible with e.g. Docker or Podman) for [rpki-client](https://www.rpki-client.org/). It's an RPKI validator to support BGP Origin Validation.

## Usage

The OCI image automatically refreshs the Validated ROA Payloads (VRPs) hourly. It may be started with Docker using:

```shell
docker run --name rpki-client \
           --volume /path/to/rpki-client/tals/arin.tal:/etc/tals/arin.tal \
           --volume /path/to/rpki-client/output:/var/lib/rpki-client \
           --volume /path/to/rpki-client/cache:/var/cache/rpki-client \
           --detach rpki/rpki-client:latest
```

And it may be started with Podman using:

```shell
podman run --name rpki-client \
           --volume /path/to/rpki-client/tals/arin.tal:/etc/tals/arin.tal \
           --volume /path/to/rpki-client/output:/var/lib/rpki-client \
           --volume /path/to/rpki-client/cache:/var/cache/rpki-client \
           --detach rpki/rpki-client:latest
```

## Volumes

  * `/etc/tals` - Directory for Trust Anchor Location (TAL) files that `rpki-client` will load by default. ARIN TAL must be [downloaded separately](https://www.arin.net/resources/manage/rpki/tal/#arin-tal) in RFC 7730 format, because the ARIN Relying Party Agreement (RPA) must be accepted.
  * `/var/lib/rpki-client` - Directory where `rpki-client` will write the output files. By default BIRD and OpenBGPD compatible outputs as well as CSV and JSON formats are generated.
  * `/var/cache/rpki-client` - Directory where `rpki-client` will store the cached repository data. To speed-up the performance, persistent storage is recommented.

While none of the volumes is required, meaningful usage requires at least persistent storage for `/var/lib/rpki-client` and the ARIN TAL.

## Environment Variables

  * `TZ` - Time zone according to IANA's time zone database, e.g. `Europe/Amsterdam`, defaults to `UTC`.
  * `ONESHOT` - Set to `true` to run `rpki-client` only once rather hourly, defaults to `false`.

## Custom images

For custom OCI images, the following build arguments can be passed:

  * `VERSION` - Git tag or branch of the portability shim, e.g. `master`, `OPENBSD_6_8` or `6.8p1`, defaults to `6.8p1`.
  * `PORTABLE_GIT` - Git repository URL of the portability shim, defaults to `https://github.com/rpki-client/rpki-client-portable.git`.
  * `PORTABLE_COMMIT` - Git commit, branch or tag of the portability shim, defaults to `$VERSION`.
  * `OPENBSD_GIT` - Git repository URL of the OpenBSD source code, defaults to `https://github.com/rpki-client/rpki-client-openbsd.git`.
  * `OPENBSD_COMMIT` - Git commit, branch or tag of the OpenBSD source code, defaults to the branch [mentioned](https://github.com/rpki-client/rpki-client-portable/blob/master/OPENBSD_BRANCH) in the portability shim.

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

As with all OCI images, these also contain other software under other licenses (such as BusyBox, OpenSSL etc. from the base distribution, along with any direct or indirect dependencies of the contained rpki-client).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
