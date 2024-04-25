---
layout: post
title:  'A new tool, lldext, and a TTD guide published at wtrace.net'
date:   2024-04-25 16:00:00 +0200
permalink: /2024/04/25/lldext-and-ttd-guide/
---

I am happy to announce a new open source tool, [lldext](https://github.com/lowleveldesign/lldext), in the wtrace.net toolkit. Its repository contains a native WinDbg plugin and various utility scripts. From some time, it is possible to write WinDbg extension commands in JavaScript (crazy, isn't it? :)). I was a bit reluctant to try this functionality in the past, but I must admit it makes writing extensions much faster. I recorded [a short video](https://youtu.be/lupFi5n7iJk?feature=shared) presenting how I use some of the lldext commands when debugging windowing functions from the user32 module. And when I mention debugging, I don't mean live debugging, but Time Travel Debugging - currently, my favorite way of diagnosing application issues. If you haven't tried it yet, I highly recommend checking it out. My [short guide](/guides/using-ttd/) on recording and analyzing TTD traces may be of some help, next to MS docs, and those older, but still great, [Defrag Tools episodes](https://learn.microsoft.com/en-us/shows/defrag-tools/?terms=ttd).
