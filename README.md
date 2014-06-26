## Scratch 2.0 editor and player [![Build Status](https://api.travis-ci.org/LLK/scratch-flash.svg?branch=master)](https://magnum.travis-ci.com/LLK/scratch-flash)
This is the open source version of Scratch 2.0 and the core code for the official version found on http://scratch.mit.edu. This code has been released under the GPL version 2 license.

If you're interested in contributing to Scratch, please take a look at the issues on this repository. Two great ways of helping Scratch are helping us identify bugs and documenting them as issues or fixing issues and creating pull requests. When submitting pull requests please be patient. The Scratch Team is very busy and it can take a while to find time to review the pull requests. Your code may require changes before being accepted or may not be suitable to acceptance. The organization and class structures can't be radically changed without significant coordination and collaboration from the Scratch Team. These types of changes should be avoided since they would impact the official version.

Unfortunately, when migrating the issues to this new repository the existing pull requests and references to other issues have been broken. We will try to clarify comments when necessary and as old issues are closed this will become less of an issue.

### Building
To build the Scratch 2.0 SWF you will need [Ant](http://ant.apache.org/), the [Flex SDK](http://flex.apache.org/) version 4.10+, and [playerglobal.swc files](http://helpx.adobe.com/flash-player/kb/archived-flash-player-versions.html#playerglobal) for Flash Player versions 10.2 and 11.4 added to the Flex SDK. Scratch is used in a multitude of settings and some users have older versions of Flash which we try to support (as far back as 10.2).

After downloading ``playerglobal11_4.swc`` and ``playerglobal10_2.swc``, move them to ``<path to flex>/frameworks/libs/player/<version>/playerglobal.swc``. E.g., ``playerglobal11_4.swc`` should be located at ``<path to flex>/frameworks/libs/player/11.4/playerglobal.swc``.

The ``build.properties`` file sets the default location for the Flex SDK. Create a ``local.properties`` file to set the location on your filesystem. Your ``local.properties`` file may look something like this:
```
FLEX_HOME=/home/joe/downloads/flex_sdk_4.11
```
Now you can run Ant ('ant' from the commandline) to build the SWF.

### Debugging
Here are a few integrated development environments available with Flash debugging support:
* [Intellij IDEA](http://www.jetbrains.com/idea/features/flex_ide.html)
* [Adobe Flash Builder](http://www.adobe.com/products/flash-builder.html)
* [FlashDevelop](http://www.flashdevelop.org/)
* [FDT for Eclipse](http://fdt.powerflasher.com/)
