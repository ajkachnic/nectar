---
sidebar_position: 1
---

# Setup

In order to work with Nectar, you need to set some things up

## Dependencies

First off, make sure you have the latest nightly Zig release. You can install this using [Zig's Getting Started guide](https://ziglang.org/learn/getting-started/). You will also need [Git](https://git-scm.com/), and can install it using [this guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

## Creating a project

Go to your projects directory, and run these commands:

```shell
mkdir project-name-here
cd project-name-here
zig init-lib # Create a basic zig project
git init # Initialize a new git repository
```

Now we have a Zig project; and from here, run these commands to set the project up for *nectar development*.

```shell
mkdir libs
git submodule add https://github.com/ajkachnic/nectar libs/nectar
```

Now, we're ready for the next stage