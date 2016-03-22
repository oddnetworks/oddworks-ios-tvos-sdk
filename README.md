Apple iOS & tvOS SDK for Oddworks
===================================
![Oddworks iOS and tvOS](https://www.oddnetworks.com/assets/img/carousel/open-source-hero.png)
An [Oddworks](https://github.com/oddnetworks/oddworks) device client SDK for Apple TV, iPhone, and iPad. Check out [Odd Networks](https://www.oddnetworks.com/) for more information.

* Create a new streaming app for iPhone and iPad
* Create your own channel on Apple TV
* Augment your existing iOS or tvOS app with video streaming content from [Oddworks](https://github.com/oddnetworks/oddworks).
* Take down the establishment.

The iOS/tvOS Frameworks for Odd Networks are written in Swift. Objective-C target applications are fully supported. You may refer to our [sample apps](https://github.com/oddnetworks/odd-sample-apps) for how to work with the SDK in both Swift and Objective-C.

_Become your own video distribution channel!_

## Table of contents

* [Resources](#resources)
* [Oddworks Content Server](#oddworks-content-server)
* [Oddworks Sample Apps](#oddworks-sample-apps)
* [Oddworks Apple Guide](#oddworks-apple-guide)
* [Technology](#technology)
* [Versioning](#versioning)
* [Motivation](#motivation)
* [Community](#community)
* [License](#license)

## Resources

#### Oddworks Content Server
The Oddworks iOS/tvOS SDK is designed specifically as a client for the open source [Oddworks Content Server](https://github.com/oddnetworks/oddworks). Together the server and client allow you to structure your content and deliver it specifically to your application.

#### Oddworks Sample Apps
The [sample apps](https://github.com/oddnetworks/odd-sample-apps) are designed as reference apps for creating content rich applications for iOS and Apple TV. These are open source as well, and should provide the quickest way to get started with this SDK for your app.


* Apple iOS & tvOS SDK (you are here) Used for iPhone, iPad, and Apple TV.
* [Android SDK](https://github.com/oddnetworks/oddworks-android-sdk) Used for mobile, tablet, Android TV, and Fire TV.

_Coming soon:_

* Roku SDK
* JavaScript SDK for use in [Windows Universal](https://msdn.microsoft.com/en-us/windows/uwp/get-started/universal-application-platform-guide) and web applications.

#### Oddworks Apple Guide
The [guide](http://apple.guide.oddnetworks.com/) contains the full documentation for working with Apple devices in the Oddworks ecosystem.
* [Quick Start](http://apple.guide.oddnetworks.com/setup/)
* [Overview](http://apple.guide.oddnetworks.com/overview/)
* [Full Walkthrough](http://apple.guide.oddnetworks.com/getting_started/tvOS_tutorial/)

## Technology

The Oddworks Platform is written for the [Node.js](https://nodejs.org/) runtime, and uses the well known [Express.js](http://expressjs.com/) framework for HTTP communication.

Oddworks is designed to be database agnostic so long as the underlying database can support JSON document storage, including some RDMSs like PostgreSQL. Currently the only supported and tested database is MongoDB.

Although communication between the devices and the REST API is typically done in a synchronous way, the inner guts of the system is designed to communicate via asynchronous message passing. This makes it easier to extend the platform with plugins and other loosely coupled modules without worrying about upstream changes like you would in tightly coupled platforms.

## Versioning

For transparency into our release cycle and in striving to maintain backward compatibility, Oddworks is maintained under [the Semantic Versioning guidelines](http://semver.org/).

## Motivation

The Oddworks Platform was designed and developed by [Odd Networks](https://www.oddnetworks.com/) to lower the barrier for developers and content owners to create your own streaming content network. Based on our experience in video gaming we thought that TV could use a big improvement. We believe in the future of television and, with the Oddworks open source platform, we hope you'll make that future a reality.

We proudly stand behind our open source work and, in addition to maintaining the Oddworks project, Odd Networks also provides hosted services, a Pro Dashboard, a Live Stream Generator, and a Recommendation Service.

Check out [www.oddnetworks.com](https://www.oddnetworks.com/)

## Community

Get updates on Odd Network's development and chat with the project maintainers and community members.

* Follow [@oddnetworks on Twitter](https://twitter.com/OddNetworks).
* Join [the official Slack room](http://slack.oddnetworks.com/).
* Submit an [issue](https://github.com/oddnetworks/oddworks/issues).
* Check out the [API sample responses](https://www.oddnetworks.com/documentation/oddworks/).
* Read and subscribe to [The Official Odd Networks Blog](http://blog.oddnetworks.com/).

## License

Apache 2.0 © [Odd Networks](http://oddnetworks.com)

