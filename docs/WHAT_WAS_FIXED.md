# What was wrong and how it was fixed

A plain-words account. The technical version, with the evidence, is in nx2android's pull request
[#403](https://github.com/shirai91/nx2android/pull/403).

## 1. No sound at all

The game uses an old version of the Switch's system libraries (SDK 3.5.0). In it, the part of the audio renderer that
nx2android drives sits at a different place inside its object than in newer versions. nx2android looked in the newer
place, every audio frame failed silently, and the game was mute. The place is now read from the game's own libraries.

## 2. The game closed at the first video

After the tutorial fight the game plays a pre-rendered video. This old SDK creates its video decoder in a way
nx2android did not handle, and the game crashed. That form is handled now.

## 3. Pictures drawn inside out

The game sets up part of its graphics state in an unusual order, and nx2android decided which side of each triangle
faces the camera from the wrong moment's setting.

## 4. Some effect shaders missing

A few of the game's compute shaders are stored without the header nx2android's shader reader expected, so they were
left out.

## 5. 30 fps

The game advances by a fixed step every frame, so simply drawing faster would make it run at double speed. The
profile's patch makes it step by real time instead, which gives 60 fps in play (cutscenes stay at 30). The pause
menu's Frame rate row switches between 30 and 60.

## 6. GPU time on Turnip

nx2android carries two workarounds for faults of Qualcomm's own driver. Turnip does not have those faults, and with
the workarounds off the GPU time on the title screen went from 12.0 to 10.0 ms a frame.

## What is still open

- Later areas, long sessions and DLC content are not tested. Only the first video was played.
- One crash on losing focus in Argentum, not reproduced.
