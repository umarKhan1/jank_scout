## 0.0.2

* Added package topics to pubspec metadata.
* Fixed insecure HTTP link warning in README.md.

## 0.0.1


* Initial release of Jank Scout.
* Frame timing drop interception via native `SchedulerBinding.instance.addTimingsCallback`.
* Active screen route tracking and attribution via `JankScoutObserver`.
* Telemetry noise suppression with a 4ms threshold buffer.
* Log flood prevention with a 2.5-second logging cooldown per route.
* Zero external package dependencies.
* Safe compile-time assertion guards that tree-shake the package logic in release builds.
