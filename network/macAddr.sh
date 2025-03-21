#!/bin/bash
ip -o link show enp4s0 | sed 's/.*ether \(\S*\).*/\1/g'
