# Circles: E2E encrypted social networking

Circles is a new kind of secure social sharing app.

You can think of it like an encrypted messenger that looks and feels like a social network.
Or you can think of Circles as a social network app where every post is encrypted from end to end.

Which is it really?  It's both, at the same time.

# Features

## End-to-end (E2E) Encryption
Every post in Circles is encrypted from your device all the way to your
friends' devices.
The only people who can see the messages and photos that you share are
the people who you have specifically invited to join your social circles
and groups.

Circles is [built on Matrix](https://matrix.org/). 
It uses the same E2E security protocols, Olm and Megolm, that Matrix uses
for its encrypted group chat.
Circles does not attempt to "roll its own" encryption code.
Instead, it uses the [Matrix iOS SDK](https://github.com/matrix-org/matrix-ios-sdk)
for all security and encryption related functions.

## Runs on iPhone, iPad, and iPod Touch
Circles for iOS should run on any device with iOS 14+.
Building a version of Circles for Android devices is one of our top priorities
for the future.

## Circles and Groups
In the Circles app, we support two different kinds of social structures:
circles and groups.

![Circles and groups screenshots](./assets/images/circles-and-groups.jpeg)

**Groups** are simpler, so let's talk about them first.

### Private Groups

A group in the Circles app works pretty much like a group anywhere else.
It has a well-defined set of members, and everyone who's in the group is
in the same group with everyone else.
Everyone in the group can see everything posted in the group.

![Groups screenshots](./assets/images/groups-screenshots.jpeg)

Any organized group of people in the real world is probably a reasonable
fit for a group in the app.
For example:
* Your book club.
* Your softball team.
* The people who live on your block, or in your building.
* Your kid's preschool classroom.
  (Well, the parents and teachers anyway.  Preschoolers definitely shouldn't be on social networks!)

**Any organized group of people with well-defined membership is probably a
reasonable fit for a group in the app.**

### Secure Social Circles

**Circles** are loose, flexible, and overlapping, just like real, organic,
human social circles.

In the real world, if you and I are friends, then your set of friends is
probably not exactly the same as my set of friends.
And that's OK.

Similarly, if you and I are family, that doesn't mean that the set of people
who you consider to be family must be exactly the same people that I call
family.
For one thing, if you and I are blood relatives, then your in-laws are
probably totally unrelated to my in-laws, and vice versa.

And, again, that's totally OK.
That's how human relationships work.
Circles are our way of helping the technology catch up to the social reality.

**A circle is a good fit for any type of relationship where every individual
has their own network of connections that's distinct from anyone else's.**

![Circles screenshots](./assets/images/circles-screenshots.jpeg)

Maybe the best way to think about a circle is that it's like your own
little private, secure version of Facebook in a microcosm.
The only people in it are the people who you really care about, and
they're only sharing things that you have some mutual interest in.
Each circle functions like your own personal "wall" or "page" where
you can share things.
It also gives you your own private timeline of updates from your
friends in that circle.

## Bonus Feature: Encrypted Photo Galleries
We also give you encrypted photo galleries.
You can share a gallery with your friends and family, or you can just
use it for yourself as an encrypted cloud backup of your photos.

![Photo gallery screenshots](/assets/images/photogallery-screenshots.jpeg)

Galleries also give you an easier way to manage photos that you want
to share with more than one of your groups or circles.
If you upload the photo into a gallery first, you can then share it
with a group or a circle with just a couple of taps on the screen.

# Try It Out
The Circles beta will be publicly available on Apple's [TestFlight](https://testflight.apple.com/)
service in mid-June 2021.
Until then, if you have a recent Mac with Xcode, you can build and run
the app yourself.

```console
[user@host ~]$ git clone https://github.com/KombuchaPrivacy/circles-ios.git
[user@host ~]$ cd circles-ios
[user@host circles-ios]$ pod install
[user@host circles-ios]$ open Circles.xcworkspace
```

**NOTE 2021/05/26**: Unless you have a signup token, you will not be able
to create an account on the beta testing server at this time.
However, if you have an existing account on another Matrix homeserver,
you can use Circles with that account by making one small change to the
code.
In [KSStore.swift](./Circles/KSStore.swift), look at lines 153-155 to change
the homeserver to the one that you want to use.

