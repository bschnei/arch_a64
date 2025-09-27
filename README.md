## What?
These scripts are used to maintain a few [Arch Linux](https://archlinux.org/) packages built for the [ARMv8-A instruction set](https://en.wikipedia.org/wiki/ARMv8-A).

## To do

- [x] build all packages in `base` and `base-devel`
- [x] build other packages that I actively use
- [ ] build packages need to build the packages above
- [ ] rebuild kernel config and keep audit trail of changes 
- [ ] create core/extra repos so devtools can be used

### packages needed for mkarchiso
- edk2
- f2fs-tools (FTBFS on aarch64 possibly gcc15 related)
- qemu-guest-agent
- usbmuxd (validity check fail)
- xl2tpd (FTBFS probably gcc15)

### packages that aren't buildling
- ncompress (FTBFS likely gcc 15 related)
- zip (FTBFS)

