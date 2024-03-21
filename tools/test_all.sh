#!/bin/bash

for i in $(ls packages) ; do
  pushd packages/"$i"

  flutter test

  popd
done
