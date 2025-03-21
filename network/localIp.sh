#!/bin/bash
ip -o addr show enp4s0 | head -n 1 | sed 's/.*inet \(\S*\)\/.*/\1/g'
