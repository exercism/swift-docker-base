# Swift Docker Base

A base Docker image for Exercism's [Swift Test Runner][swift-test-runner].  
The image is based on the official [Swift Docker image][swift-docker-image] and has been modified to reduce its size by removing unused software.

## Building and Testing

[Docker][docker] is required to run tests locally.  
Running `bin/ci_build.sh` will build the Docker image and test it using a dummy Swift CLI project.  
The build log will include some meta-information about the Docker image.

## Reducing docker image size

To reduce image size the following techics are applied:
1. Docker number of layers is minimal.
2. All binaries that are not take part in build and test process are removed.
3. Required binaries are stripped with `strip`.

> [!NOTE]
> Any new techniques should not degrade the build performance of Exercism track tools that are based on this image.

## License

This repository includes [Dockerfile][dockerfile] from [swiftlang/swift-docker][swift-docker-image], originally licensed under the Apache License 2.0.
The rest of the repository is licensed under the AGPL-3.0.

[dockerfile]: Dockerfile
[swift-test-runner]: https://github.com/exercism/swift-test-runner
[swift-docker-image]: https://github.com/swiftlang/swift-docker
[docker]: https://www.docker.com/get-started/