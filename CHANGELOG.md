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
