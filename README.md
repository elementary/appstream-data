# AppStream data for Pantheon

Launchpad PPAs do not support AppStream data in the sense that it is not globbed together for each package in a PPA and published to the repository in the way that it would be downloaded with an `apt update`.

To work around this and provide AppStream data for elementary packages available from the `stable` PPA, the `build.sh` script in this repository downloads a local mirror of the PPA and runs `appstream-generator` on it to generate the necessary metadata tarball. This is then packaged up as a `.deb` package and uploaded to the same PPA. When installed, it puts the metadata in a location where AppStream would expect to find it.

Building this metadata properly requires the `elementary-icon-theme` package to be installed so that the relevant icons can be extracted. So in a CI environment, an elementary Docker container is used. To build the metadata locally, you can use the following command:

`docker run -i -v ${PWD}:/repo elementary/docker:stable /bin/bash -s bionic stable < build.sh`
