![A logo form of "nectar"](assets/logo.svg)
<!-- # nectar -->

A cross-platform audio plugin platform for Zig.

***WARNING***: *This is in like a pre-alpha state, and probably very buggy and incomplete; Here be dragons*

Nectar is made up of a number of packages:

- [`nectar/core`](/core/README.md) - Core utilities and tools used across most other packages
- [`nectar/midi`](/midi/README.md) - Mostly *tested* MIDI Parser
- [`nectar/vst2`](/vst2/README.md) - Bindings to the VST 2.4 SDK and some utilities
- [`nectar/standalone`](/standalone/README.md) - Bindings to libsoundio for standalone applications

## Project Status

*As of August 23rd, 2022:*

Nectar has basic support for building a VST2 plugin, with a cross-platform interface. But things like GUI Support, other plugin formats, and general DSP abstractions are not here yet.
I've created issues for all of the features I plan on supporting for an alpha v0.1 release. Here's an abridged list:

- [ ] [Redesign parameter API](https://github.com/ajkachnic/nectar/issues/2)
- [ ] [Tweak build setup and make it less complex](https://github.com/ajkachnic/nectar/issues/3)
- [ ] [Document core APIs](https://github.com/ajkachnic/nectar/issues/6)
- [ ] [Add Clap plugin support](https://github.com/ajkachnic/nectar/issues/7)
- [ ] Add VST3 plugin support
- [ ] Add GitHub actions for automated builds and tests
- [ ] Possibly: Add basic GUI support (more likely, just creating windows and nanovg-style drawing)

See [here](https://github.com/ajkachnic/nectar/milestone/1) for the full list of issues.

### Long term goals

Thinking further ahead than just the next release, here are some goals I'd like to achieve before a 1.0 release.

- [ ] GUI support with proper widgets and layout
- [ ] Standalone support (pretty much requires GUI support)
- [ ] Numerous tutorials and resources on the docs website
- [ ] A nice, easy to use DSP library
- [ ] ~100% test coverage for applicable packages
- [ ] Get some outside contributors and people excited about Zig audio involved
- [ ] Potentially redesign the docs site

### Planned Targets (checked are implemented)

- [x] VST2
- [ ] VST3
- [ ] CLAP
- [ ] Standalone (libsoundio)
- [ ] LV2
