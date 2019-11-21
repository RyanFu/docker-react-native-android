#!/bin/bash

echo $1

remote_adb=$1

adb connect $remote_adb

adb wait-for-device

yarn start & yarn android

wait