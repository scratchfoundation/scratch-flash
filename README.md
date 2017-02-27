## Scratch 2.0 editor and player [![Build Status](https://api.travis-ci.org/LLK/scratch-flash.svg?branch=master)](https://travis-ci.org/LLK/scratch-flash)
This is the open source version of Scratch 2.0 and the core code for the official version found on http://scratch.mit.edu. This code has been released under the GPL version 2 license. Forks can be released under the GPL v2 or any later version of the GPL.

If you're interested in contributing to Scratch, please take a look at the issues on this repository. Two great ways of helping Scratch are by identifying bugs and documenting them as issues, or fixing issues and creating pull requests. When submitting pull requests please be patient -- the Scratch Team is very busy and it can take a while to find time to review them. The organization and class structures can't be radically changed without significant coordination and collaboration from the Scratch Team, so these types of changes should be avoided.

It's been said that the Scratch Team spends about one hour of design discussion for every pixel in Scratch, but some think that estimate is a little low. While we welcome suggestions for new features in our <a href="http://scratch.mit.edu/discuss/1/">suggestions forum</a> (especially ones that come with mockups), we are unlikely to accept PRs with new features that we haven't deeply thought through. Why? Because we have a strong belief in the value of keeping things simple for new users. To learn more about our design philosophy, see this <a href="http://scratch.mit.edu/discuss/post/1576/">forum post<a>, or <a href="http://web.media.mit.edu/~jmaloney/papers/ScratchLangAndEnvironment.pdf">this paper</a>.

### Building

The Scratch 2.0 build process now uses [Gradle](http://gradle.org/) to simplify the process of acquiring dependencies: the necessary Flex SDKs will automatically be downloaded and cached for you. The [Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html) is included in this repository, but you will need a Java Runtime Environment or Java Development Kit in order to run Gradle; you can download either from Oracle's [Java download page](http://www.oracle.com/technetwork/java/javase/downloads/index.html). That page also contains guidance on whether to download the JRE or JDK.

There are two versions of the Scratch 2.0 editor that can be built from this repository. See the following table to determine the appropriate command for each version. When building on Windows, replace `./gradlew` with `.\gradlew`.

Required Flash version | Features | Command
--- | --- | ---
11.6 or above | 3D-accelerated rendering | `./gradlew build -Ptarget=11.6`
10.2 - 11.5 | Compatibility with older Flash (Linux, older OS X, etc.) | `./gradlew build -Ptarget=10.2`

A successful build should look something like this (SDK download information omitted):

```sh
$ ./gradlew build -Ptarget=11.6
Defining custom 'build' task when using the standard Gradle lifecycle plugins has been deprecated and is scheduled to be removed in Gradle 3.0
Target is: 11.6
Commit ID for scratch-flash is: e6df4f4
:copyresources
:compileFlex
WARNING: The -library-path option is being used internally by GradleFx. Alternative: specify the library as a 'merged' Gradle dependendency
:copytestresources
:test
Skipping tests since no tests exist
:build

BUILD SUCCESSFUL

Total time: 13.293 secs
```

Upon completion, you should find your new SWF in the `build` subdirectory.

```sh
$ ls -R build
build:
10.2  11.6

build/10.2:
ScratchFor10.2.swf

build/11.6:
Scratch.swf
```

Please note that the Scratch trademarks (including the Scratch name, logo, Scratch Cat, and Gobo) are property of MIT. For use of these Marks, please see the [Scratch Trademark Policy](http://wiki.scratch.mit.edu/wiki/Scratch_1.4_Source_Code#Scratch_Trademark_Policy).

### Debugging
Here are a few integrated development environments available with Flash debugging support:
* [Intellij IDEA](http://www.jetbrains.com/idea/features/flex_ide.html)
* [Adobe Flash Builder](http://www.adobe.com/products/flash-builder.html)
* [FlashDevelop](http://www.flashdevelop.org/)
* [FDT for Eclipse](http://fdt.powerflasher.com/)

It may be difficult to configure your IDE to use Gradle's cached version of the Flex SDK. To debug the Scratch 2.0 SWF with your own copy of the SDK you will need the [Flex SDK](http://flex.apache.org/) version 4.10+, and [playerglobal.swc files](http://helpx.adobe.com/flash-player/kb/archived-flash-player-versions.html#playerglobal) for Flash Player versions 10.2 and 11.4 added to the Flex SDK.

After downloading ``playerglobal11_4.swc`` and ``playerglobal10_2.swc``, move them to ``<path to flex>/frameworks/libs/player/<version>/playerglobal.swc``. E.g., ``playerglobal11_4.swc`` should be located at ``<path to flex>/frameworks/libs/player/11.4/playerglobal.swc``.

Consult your IDE's documentation to configure it for your newly-constructed copy of the Flex SDK.

If the source is building but the resulting .swf is producing runtime errors, your first course of action should be to download version 4.11 of the Flex SDK and try targeting that. The Apache foundation maintains an [installer](http://flex.apache.org/installer.html) that lets you select a variety of versions.
