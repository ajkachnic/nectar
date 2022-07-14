# nectar

[![MIDI Parser Coverage Badge](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/ajkachnic/6ea115f49e2287c836280743aa4f88d9/raw/nectar__heads_main.json)]

A cross-platform audio plugin platform for Zig.

***WARNING***: *This is in like a pre-alpha state, and probably very buggy and incomplete; Here be dragons*

Nectar is made up of a number of packages:

- [`nectar/core`](/core/README.md) - Core utilities and tools used across most other packages
- [`nectar/midi`](/midi/README.md) - Mostly *untested* MIDI Parser
- [`nectar/vst2`](/vst2/README.md) - Bindings to the VST 2.4 SDK and some utilities
- [`nectar/standalone`](/standalone/README.md) - Bindings to libsoundio for standalone applications

## Targets (checked are implemented)

- [x] VST2
- [ ] Standalone (JACK)
- [ ] LV2
- [ ] VST3
- [ ] CLAP
