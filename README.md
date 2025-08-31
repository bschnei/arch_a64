## What?
These scripts are used to maintain a few [Arch Linux](https://archlinux.org/) packages built for the [ARMv8-A instruction set](https://en.wikipedia.org/wiki/ARMv8-A).

## ARM Instruction Sets

ARMv8-A is the first version of the ARM architecture to support 64-bit instructions. There have been multiple extensions of the v8 instruction set. These are indicated by a minor version number (ARMv8.1-A, ARMv8.2-A, etc.). For example, the [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) uses the [Cortex-A72](https://en.wikipedia.org/wiki/ARM_Cortex-A72) which uses the ARMv8-A instruction set, while the [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) uses the [Cortex-A76](https://en.wikipedia.org/wiki/ARM_Cortex-A76) which includes ARMv8.2-A extensions.

This [table](https://en.wikipedia.org/wiki/Template:Application_ARM-based_chips) is a helpful reference for understanding which products and CPUs use which version. But be aware that a CPU advertised as being a certain model may have different features depending on the date it was manufactured and/or its purpose in the final product. `lscpu` can provide helpful information for determining exactly what features/flags are supported by--as well as what _issues_ might affect--a specific CPU. Sample output for a Cortex-A53 (ARMv8-A):

```
Architecture:                aarch64
  CPU op-mode(s):            32-bit, 64-bit
  Byte Order:                Little Endian
CPU(s):                      2
  On-line CPU(s) list:       0,1
Vendor ID:                   ARM
  Model name:                Cortex-A53
    Model:                   4
    Thread(s) per core:      1
    Core(s) per cluster:     2
    Socket(s):               -
    Cluster(s):              1
    Stepping:                r0p4
    Frequency boost:         disabled
    CPU(s) scaling MHz:      17%
    CPU max MHz:             1200.0000
    CPU min MHz:             200.0000
    BogoMIPS:                25.00
    Flags:                   fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
```

and for a Neoverse-N1 (ARMv8.2-A):

```
Architecture:                aarch64
  CPU op-mode(s):            32-bit, 64-bit
  Byte Order:                Little Endian
CPU(s):                      8
  On-line CPU(s) list:       0-7
Vendor ID:                   ARM
  Model name:                Neoverse-N1
    Model:                   1
    Thread(s) per core:      1
    Core(s) per socket:      8
    Socket(s):               1
    Stepping:                r3p1
    BogoMIPS:                50.00
    Flags:                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asim drdm lrcpc dcpop asimddp
```

Note the additional flags available for the Neoverse-N1. The presence of a flag indicates support for that feature/instruction. For example, the presence of the `atomics` flag indicates support for the [Large System Extensions (LSE)](https://learn.arm.com/learning-paths/servers-and-cloud-computing/lse/intro/) feature.

Because extensions _add_ new features to the instruction set, programs compiled for a specific instruction set are not backwards compatible. For example, programs compiled with gcc using a [target architecture option](https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html#index-march) of `-march=armv8-a` will run on ARMv8.2-A processors, but programs compiled with `-march=armv8.2-a` will include the `lse` feature and are not expected to work in general on ARMv8-A processors.

The absence of LSE support is known to cause issues building certain packages:
- [qt6-webengine](https://gitlab.archlinux.org/archlinux/packaging/packages/qt6-webengine)

## Stuff to do

- [x] build all packages in `base` and `base-devel`
- [ ] rebuild kernel config and keep audit trail of changes 

### packages that won't build but are needed to build one or more packages in `base`

- java-openjdk ([FTBFS](https://bugs.openjdk.org/browse/JDK-8354941?focusedId=14788005&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel) and needs mods)
- ncompress (FTBFS likely gcc 15 related)
- zip (FTBFS)

