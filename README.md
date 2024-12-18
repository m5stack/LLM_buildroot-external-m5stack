# AX630C Buildroot external tree

include uboot linux-kernel msp
This repository is a Buildroot `BR2_EXTERNAL` tree dedicated to
supporting the [STMicroelectronics](https://www.st.com)
[STM32MP1](https://www.st.com/en/microcontrollers-microprocessors/stm32mp1-series.html)
platforms. Using this project is not strictly necessary as Buildroot
itself has support for STM32MP1, but this `BR2_EXTERNAL` tree provide
example configurations demonstrating how to use the different features
of the STM32MP1 platforms.

## Available configurations

This `BR2_EXTERNAL` tree provides ten example Buildroot
configurations:

1. `m5stack_module_llm_4_19_defconfig`, which is a minimal configuration to
   support the AX630C LLM Discovery Kit board. It builds the U-Boot bootloader, Linux kernel
   and a minimal user-space composed of just Busybox.

2. `m5stack_ax630c_lite_4_19_defconfig`, which is a minimal configuration to
   support the AX630C Kit Discovery Kit 
   board. It builds the U-Boot bootloader, Linux kernel
   and a minimal user-space composed of just Busybox.

Note that upstream Buildroot also contains pre-defined configurations
for AX630C platforms, but they use the upstream versions of U-Boot and Linux, 
while the configurations in this `BR2_EXTERNAL` tree
use the versions provided and supported by M5STACK.

## Starter package

If want to use Buildroot on AX630C platforms without building
everything yourself from source, we provide below a *Starter
Package*. For each release and each Buildroot configuration, we
provide:

* A README file that documents how the *Starter Package* has been
  built

* A pre-built image, ready to flash on an SD card, together with a
  *Block map* (which can be used with `bmaptool` to optimize the
  flashing process). This image contains a fully working system, with
  Linux kernel and root filesystem. Look at the [flash
  and boot section](#Flashing-and-booting-the-system) to discover how
  to use the prebuilt images.

* A Software Development Kit (SDK) that contains a cross-compiler and
  set of libraries that allow you to build applications for the
  target. See the Buildroot [advanced usage
  documentation](https://buildroot.org/downloads/manual/manual.html#_advanced_usage)
  to find out how to use the SDK.

* The complete list of open-source licenses and complete source code
  of all software components included in the pre-built image, for
  license compliance.

## Building Buildroot from source

### Pre-requisites

In order to use [Buildroot](https://www.buildroot.org), you need to
have a Linux distribution installed on your workstation. Any
reasonably recent Linux distribution (Ubuntu, Debian, Fedora, Redhat,
OpenSuse, etc.) will work fine.

Then, you need to install a small set of packages, as described in the
[Buildroot manual System requirements
section](https://buildroot.org/downloads/manual/manual.html#requirement).

For Debian/Ubuntu distributions, the following command allows to
install the necessary packages:

```bash
$ sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git
```

There are also optional dependencies if you want to use Buildroot features
like interface configuration, legal information or documentation.
Please see the [corresponding manual section](https://buildroot.org/downloads/manual/manual.html#requirement-optional).

### Getting the code

This `BR2_EXTERNAL` tree is designed to work with the `2023.02.x` LTS
version of Buildroot. However, we needed a few changes on top of
upstream Buildroot, so you need to use our own Buildroot fork together
with this `BR2_EXTERNAL` tree, and more precisely its `st/2023.02.10`
branch.

```bash
$ git clone -b st/2023.02.10 https://github.com/bootlin/buildroot.git
```

See our documentation on [internal details](docs/internals.md) for more
information about the changes we have compared to upstream Buildroot.

Now, clone the matching branch of the `BR2_EXTERNAL` tree:

```bash
$ git clone https://github.com/m5stack/LLM_buildroot-external-m5stack.git
```

You now have side-by-side a `buildroot` directory and a
`buildroot-external-st` directory.

### Configure and build

Go to the Buildroot directory:

```bash
$ cd buildroot/
```

And then, configure the system you want to build by using one of the 4
*defconfigs* provided in this `BR2_EXTERNAL` tree. For example:

```bash
buildroot/ $ make BR2_EXTERNAL=../LLM_buildroot-external-m5stack m5stack_module_llm_4_19_defconfig
```

We are passing two informations to `make`:

1. The path to `BR2_EXTERNAL` tree, which we have cloned side-by-side
to the Buildroot repository

2. The name of the Buildroot configuration we want to build.

If you want to further customize the Buildroot configuration, you can
now run `make menuconfig`, but for your first build, we recommend you
to keep the configuration unchanged so that you can verify that
everything is working for you.

Start the build:

```bash
buildroot/ $ make
```

This will automaticaly download and build the entire Linux system for
your STM32MP1 platform: cross-compilation toolchain, firmware,
bootloader, Linux kernel, root filesystem. It might take between 30
and 60 minutes depending on the configuration you have chosen and how
powerful your machine is.

## Flashing and booting the system

The Buildroot configurations generate a compressed ready-to-use SD card
image, available as `output/M5_LLM_buildroot_20241214.axp`. You can also use the
prebuilt images downloaded from the [starter package section](#Starter-package).

Flash this image on LLM:[https://docs.m5stack.com/en/guide/llm/llm/image](https://docs.m5stack.com/en/guide/llm/llm/image)


# Going further

# References

* [Buildroot](https://buildroot.org/)
* [Buildroot reference manual](https://buildroot.org/downloads/manual/manual.html)
* [Buildroot system development training
  course](https://bootlin.com/training/buildroot/), with freely
  available training materials

# Support

You can contact Bootlin at dianjixz@m5stack.com for commercial support on
using Buildroot on AX630C platforms.
