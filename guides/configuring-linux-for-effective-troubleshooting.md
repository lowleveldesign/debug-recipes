---
layout: page
title: Configuring Linux for effective troubleshooting
date: 2025-12-26 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Configuring debug symbols](#configuring-debug-symbols)

<!-- /MarkdownTOC -->

Configuring debug symbols
-------------------------

These days many debugging tools can fetch debug symbols from debuginfod servers. The [official project page](https://sourceware.org/elfutils/Debuginfod.html) lists the URLs you should use for each supported distribution. For example, in my Arch Linux, the `DEBUGINFOD_URLS` environment variable is set to `https://debuginfod.archlinux.org` by the `/etc/profile.d/debuginfod.sh` script (a part of the libelf package).

If you want this variable to be preserved when running commands with sudo, you can add a rule such as the following to a file in `/etc/sudoers.d/` (e.g., `/etc/sudoers.d/debuginfod`):

```
Defaults env_keep += "DEBUGINFOD_URLS"
```
