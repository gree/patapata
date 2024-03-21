#!/bin/bash

for i in $(ls packages) ; do
  pushd packages/"$i"

  flutter pub get

  popd
done
