# 0.4.0+6

- Fix executePendingJobs (wasn't dispatching in the most current version)
# 0.4.0+5

- Removed console.log from fetch.js

# 0.4.0+4

- Fixed issue on xhr requests - wasn't passing headers to the requests

# 0.4.0+3

- Fixed dynamic library load for tests
- Added info about tests into the [README.md](README.md)

# 0.4.0+2
- Updated README.md with information about github repository containing the C bridge used on
Windows and Linux

# 0.4.0+1
- Updated README.md
# 0.4.0+0

- Added support to windows, macos and linux platforms
- Fixed fetch error
- Improved the channels/dart callback integration
# 0.3.0+0

- Null-safety migration
# 0.2.4+0

- Updated ffi, http dependencies
- Upgraded code for compatibility with ffi 1.0.0

# 0.2.3+0

- Updated QuickJS engine to version 2020-11-08
- Fix fetch

# 0.2.2+0

- Updated QuickJS engine to version 2020-09-06

# 0.2.1+0

- Updated to use QuickJS through Dart ffi instead of Platform Channel

# 0.2.0+0

- Updated to use QuickJS through PlatformChannel on Android (with this change, Android apk added size will return to be minimal )
- Change QuickJS integration to call Android platform in a sync way through http
- Added option to use JavascriptCore on Android

# 0.1.0+2

- Small fixes in the documentation on README.md

# 0.1.0+1

- Add example of onMessage (bridge which allow javascript code to call Dart) 
in the README.md

# 0.1.0+0

- Changed to use Dart FFI to call the Javascript Runtimes: QuickJS by Default in Android and JavascriptCore in iOS

# 0.0.3+1

- Updated to use a new version of oasis-jsbridge-android which brings *quickjs* (js engine for Android) 
upgraded to the latest version (currently 2020-07-05)

# 0.0.2+1

* Upgraded to use [oasis-jsbridge-android](https://github.com/p7s1digital/oasis-jsbridge-android) library under the hood

# 0.0.1+2

* Fixed a typo in the FlutterJsPlugin.kt class



# 0.0.1+1

* Initial version only provides a very simple api which allow to init the javascript engine and evaluate javascript expressions and get the result as String.


