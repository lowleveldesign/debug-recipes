---
layout: page
title: Configuring Linux for effective troubleshooting
date: 2025-06-25 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Configuring debug symbols](#configuring-debug-symbols)
- [Installing monitoring tools](#installing-monitoring-tools)
    - [Mission Center (GUI)](#mission-center-gui)
    - [Glances (TUI and Web)](#glances-tui-and-web)
    - [htop (TUI)](#htop-tui)
    - [Resources (GUI)](#resources-gui)
    - [TuxManager (GUI)](#tuxmanager-gui)

<!-- /MarkdownTOC -->

Configuring debug symbols
-------------------------

These days many debugging tools can fetch debug symbols from debuginfod servers. The [official project page](https://sourceware.org/elfutils/Debuginfod.html) lists the URLs you should use for each supported distribution. For example, in my Arch Linux, the `DEBUGINFOD_URLS` environment variable is set to `https://debuginfod.archlinux.org` by the `/etc/profile.d/debuginfod.sh` script (a part of the libelf package).

If you want this variable to be preserved when running commands with sudo, you can add a rule such as the following to a file in `/etc/sudoers.d/` (e.g., `/etc/sudoers.d/debuginfod`):

```
Defaults env_keep += "DEBUGINFOD_URLS"
```

Installing monitoring tools
---------------------------

If you are looking for a tool that will allow you to monitor running processes in the system, you may consider installing one of the  tools listed below

### Mission Center (GUI)

[Mission Center](https://missioncenter.io/) is my favourite GUI app listing processes running in the system as well as providing insights into system CPU and memory usage, and services status. On Arch, install using:

```sh
sudo pacman -Sy mission-center
```

### Glances (TUI and Web)

[Glances](https://nicolargo.github.io/glances/) is also an interesting choice if you're looking for a TUI or web application. You may run it with uv, for example:

```sh
uvx --with fastapi --with uvicorn --with jinja2 glances -w --bind 127.0.0.1
# or equivalent
uv tool run --with fastapi --with uvicorn --with jinja2 glances -w --bind 127.0.0.1
```

Then open <http://127.0.0.1:61208/> in the browser. The 'h' key will show you available shortcuts.

### htop (TUI)

Bofore I switched to Mission Center, [htop](https://htop.dev/) was for a long time my favorite monitoring tool. If you're looking for a modern `top` replacement, `htop` might be a good choice.

### Resources (GUI)

[Resources](https://apps.gnome.org/Resources) is a monitoring app which will become a default Gnome system montoring app, very similar to Mission Center.

### TuxManager (GUI)

[TuxManager](https://github.com/benapetr/TuxManager) is a Qt-based monitoring app, similar to Microsoft's Task Manager.

