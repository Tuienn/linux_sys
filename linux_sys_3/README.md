# Find Max Kernel Module

## Description

This Linux kernel module finds the maximum value within an array of integers provided as a module parameter during loading. It then prints the maximum value and all the indices (positions) where this maximum value occurs in the array.

## Author

longsontuyen

## Prerequisites

Before building and loading this module, ensure you have the necessary tools and kernel headers installed. On Debian/Ubuntu based systems, run:

```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```
