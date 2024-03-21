#!/bin/bash

for i in $(ls packages) ; do
  pushd packages/"$i"

  dart doc .

  popd
done

pushd packages/patapata_core/android

gradle clean

./gradlew dokkaHtml

popd

pushd packages/patapata_core/ios

swift doc generate . --base-url http://localhost:8080/ --module-name patapata_core --output doc --format html

popd