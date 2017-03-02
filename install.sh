#!/bin/bash

wipefs -af /dev/sda
wipefs -af /dev/sdb
coreos-install -d /dev/sda -C stable -c cloud-config.yaml
