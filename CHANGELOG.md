# v1.0.4
* Show the "Share" sheet when user taps the QR code for a circle/group/gallery
* Add ability to set default user permissions for your timeline/group/gallery
* Handle scanning QR code when you already have an invitation
* Always hide posts, photos, and reactions from ignored users

# v1.0.3
* Bugfix: Ignore invalid config object in account data
* Handle redacted email addresses in email authentication
* Bugfix: Remove groups from the UI when you leave them
* Bugfix: Ensure that we have all our friends' keys before we post
* Automatically request keys for any post that we can't decrypt

# v1.0.2
* Add support for recovering account via email auth and resetting password
* Add support for importing recovery key from Element or other clients
* Bugfix: Duplication of replies and circles in the UI
* Bugfix: Missing or wrongly sized avatars
* Bugfix: Very long names overflow the "New photo gallery" UI
* Bugfix: Prevent duplicates when selecting users to invite
* Request GDPR delete / erasure of content when deactivating account

# v1.0.1
* Add support for push notifications
* Add API declarations for the App Store
* Add cross-signing on the user's 2nd/3rd/etc devices
* Add a Settings screen for configuring notifications
* Bugfix: Re-enable cryptographic/UIA login

# v1.0.0
* Bugfix: Stop the composer blanking when the room updates
* Only show the "+" button for a new post when we have power to post

# v0.9.9
* Update copyright information
* Link to the app's privacy policy and EULA from the Settings tab

# v0.9.8
* Bugfix: Use the correct signup flow for free subscriptions
* Request refreshable access token at signup

# v0.9.7
* Clean up invitation detail views
* Make requests for invitations more visible in dark mode
* Remove photo gallery from our list when we leave
* Automatically load photos when scrolling through a gallery
* Prevent reactions from getting squished
* Update your profile picture everywhere when you choose a new one
* Get rid of the ugly password nag screen
* Speed up creating the Circles space hierarchy
* Add the ability to share or delete individual photos
* Clean up the circle/group/gallery creation dialogs to work better on iPad
* Delete uploaded media when deleting the post that references them
* Bugfix: Set displayname and profile photo on the server at setup time
* Bugfix: Enable taking new photo for your profile
* Bugfix: Enable posting new photo from the camera
* Make deletion safe again: Don't re-use already uploaded media
* Update privacy policy URL

# v0.9.6
* Fix decryption errors for messages posted while the user is invited
* Add a debug details section to the room settings
* Disable Apple Vision, since we have no way to test it

# 0.9.5
* Bugfix: More sync failures that lead to decryption errors
* Show even more info in debug mode

# 0.9.4
* iPad: Disable portrait orientation
* iPad: Make selected circle/group/gallery more legible
* Bugfix: Remove unused sections in Settings
* Add support for legacy Matrix password authentication

# 0.9.3
* Internal updates for smoother and more reliable login/signup
* Bugfix: Always sync with the server on re-open
* Bugfix: Handle brand-new accounts on self-hosted servers

# 0.9.2
* Relax password strength requirements
* Use shared web credentials and Keychain for passwords
* Save secret-storage keys in iCloud Keychain for account recovery
* Bugfix: Use new jdenticon avatar on the People tab self-view
* Bugfix: Remove TESTING section on subscription settings

# 0.9.1
* Clean up the group creation dialog
* Change default domain from circu.li to circles.futo.org
* Better handling of accounts that are in very large Matrix chat rooms
* New free subscription type for free accounts
* Make the reply composer scrollable
* Use jdenticons as profile image for users who don't upload a photo

# 0.9.0
* Show follower count for each timeline you're following
* Don't show direct follows as friends of friends
* Add screens to find and invite friends of friends in circles and groups
* Bugfix: Fix new invitations not appearing until restart
* Enable sending multimedia (image/video) replies
* Don't require uploading a photo on account setup
* Add "pull down to refresh"
* Improved navigation: Reduce wasted space at the top of the screen on iPhone
* Show basic information about polls
* More consistent wording: "passphrase" instead of "password"
* Show when a message has been edited
* Initial support for in-app subscriptions
* Clean up landscape view for iPad
* Stop sending Blurhash for image posts
* Use refresh tokens if the server provides them
* Show search suggestions when inviting friends to a new circle or group
* Save image now works again
* New Share button for image posts
* New Copy button for text posts
* Bugfix: Enable replying to an edited post
* Various UI clean-up and bug fixes

# 0.8.3
* Store keys locally in the Keychain
* Don't require room version 11, in case the server doesn't support it

# 0.8.2
* Internal-only build for testing Keychain

# 0.8.1
* Support for subscribing to email updates when enrolling a new email address
* Remember previously-used user id's on the login screen
* Updated Circles icons
* Clean up the UI for inviting users
* Suggest corrections when the user mis-types a user id
* Blur images in invitations from unknown users
* Clean up permissions and power levels
* New settings screens for circles, groups, and photo galleries
* Use a master/detail view on the Settings tab
* Show friends of friends on the People tab
* New UI for managing which circles are advertised to friends in your profile
* Emoji reactions are now tappable buttons

# 0.8.0
* Added support for regular Matrix accounts on other servers

# 0.7.1
* Only show the Group security sheet when in debug mode
* Added share by link
* MSC3061: Provide keys for older messages when inviting a new user
* Initial support for handling deep links
* Support for handling QR codes containing deep links
* Generate QR codes in the new deep link format

# 0.7.0
* Bugfix: Load emoji reactions correctly
* Improve pinch-to-zoom for photo galleries
* Bugfix: Handle QR codes from Circles Android
* Initial support for deep links, at the top level of the app and on the Groups tab

# 0.6.1
* Split the photo galleries list into "My Galleries" and "Shared Galleries"
* Show the gallery owner's name and photo on shared galleries
* Updated the layout of the basic timeline post
* Added unread post counts on circle and group overviews
* Added support for sending read receipts
* Bugfix: Make sure we fetch the cover image for each circle/group/gallery

# 0.6.0
* Added the ability to edit posts
* Added the ability to request invitation by scanning QR code
* Added quick reactions to the emoji picker
* Added some missing context menus
* Added highlighting for posts that mention you
* Bugfix: Make invitation indicators more responsive to new invites
* Hide state events in the timeline by default
* Bugfix: Create "people" and "profile" spaces if they do not exist

# 0.5.3
* Improved support for redactions
* Fixed compatibility problems for accounts created with Circles Android

# 0.5.2
* Improved default avatar images for groups, circles, and photo galleries
* Only moderators and admins can can send invites
* Improved support for password managers
* Create the first photo gallery when we set up the account
* Various bug fixes

# 0.5.1
* Add ability to encrypt and upload videos and post them as m.video messages
* Centered the Circle timeline
* Prevent creation of a Group without a name
* Validate user_id's on invite
* Fix the profile invite button

# 0.5.0
* Add pinch to zoom on the photo gallery's grid view
* Add support for playing `m.video` posts
* Fix buttons getting stuck in a disabled state when async tasks fail
* Improve support for secret storage, when it's already been set up by another app

# 0.4.1
* Send caption for image posts, if they have one
* Don't allow user to block themself
* Hide menu items for managing/inviting members when the user does not have those powers
* Don't send BlurHash, it crashes Circles Android

# 0.4.0
* Fixed a compatibility issue with Circles Android in the BS-SPEKE authentication.  Unfortunately this breaks existing Circles iOS accounts.
* Added support for leaving groups and photo galleries
* Improved the interface for reviewing group invitations
* Replaced the randomized circles image with the actual Circles logo
* Added stock photos to the Help dialog to illustrate the difference between circles and groups
* Show an error when the username stage fails at signup
* Ask for confirmation when canceling signup

# 0.3.0
* Fixed issue where login screens will spin forever
* Fixed layout issues with master-detail views on iPad
* Fixed layout issues with circles/groups "Help" dialog on iPad
* Added support for switching users without logging out
* Added support for deactivating account (required for EU)
* Added confirmation dialog for logout
* Added suggestions for invalid user id at login

# 0.2.2
* Fixed what seem to be the last login issues on iOS

# 0.2.1
* Fixed even more login issues on iOS

# 0.2.0
* Fixed various login issues on iOS

# 0.1.0
* Initial TestFlight beta
* Basic support for most things that a social app needs to do -- posting, scrolling timelines, managing connections
