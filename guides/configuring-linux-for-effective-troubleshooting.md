---
layout: page
title: Configuring Linux for effective troubleshooting
date: 2025-06-25 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Configuring debug symbols](#configuring-debug-symbols)
- [Installing monitoring tools](#installing-monitoring-tools)
    - [GUI tools](#gui-tools)
    - [TUI tools](#tui-tools)

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

### GUI tools

- [Mission Center](https://missioncenter.io/) is my favourite GUI app listing processes running in the system as well as providing insights into system CPU and memory usage, and services status. On Arch, install using: `sudo pacman -Sy mission-center`
- [Resources](https://apps.gnome.org/Resources) is a monitoring app which will become a default Gnome system montoring app, very similar to Mission Center
- [TuxManager](https://github.com/benapetr/TuxManager) is a Qt-based monitoring app, similar to Microsoft's Task Manager.

### TUI tools

- [btop](https://github.com/aristocratos/btop)
- [Glances](https://nicolargo.github.io/glances/) is an interesting choice if you're looking for a TUI or web application. You may run it with uv, for example: `uv tool run --with fastapi --with uvicorn --with jinja2 glances -w --bind 127.0.0.1`. Then open <http://127.0.0.1:61208/> in the browser. The 'h' key will show you available shortcuts.
- [htop](https://htop.dev/)

