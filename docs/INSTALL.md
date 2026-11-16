# Install, step by step

## Before you start

- **Computer**: macOS or Linux, Python 3.11 or newer, git, about 35 GB free.
- **Device**: arm64 Android, about 15 GB free. Turn on *Developer options* and *USB debugging*, connect it by USB and
  accept the "Allow USB debugging?" question on its screen.
- **Your files**: the base game (`0100E95004038000`), update 2.1.0 (`0100E95004038800`, v983040) and `prod.keys`.

## Steps

1. Copy the game files and `prod.keys` into `put-game-files-here/`. Any file names work. If they are on the same drive
   as this folder they are linked, not copied.
2. Copy the Turnip driver's `libvulkan_freedreno.so` into `drivers/` ([which one](../drivers/README.md)).
3. Run `./setup.sh check`. Every line should show something found.
4. Run `./setup.sh`. In order, it:
   - fetches nx2android at the tested commit into `work/nx2android` (about 320 MB);
   - makes a private Python environment in `work/venv`;
   - asks before letting nx2android download the Android NDK, the .NET SDK and adb (about 2 GB, kept in nx2android's
     own tools folder in your user profile, not in this folder);
   - extracts the game (about 14 GB), rewrites its program, translates its 12,750 shaders, builds the app;
   - installs the app and copies its data to the device (about 14 GB the first time).
5. Open the game on the device.

## Other commands

- `./setup.sh build`: everything but the install.
- `./setup.sh install`: install what was built, for example on a second device.
- `NX2A_DIR=/path/to/nx2android ./setup.sh`: use an nx2android checkout you already have (it must contain the changes
  of pull request 403).
- `SETUP_YES=1 ./setup.sh`: do not ask before downloading the tools.

## Where things are

- On the computer: `work/nx2android/.gamedump/XenobladeChronicles2/` holds the extracted game, the build logs
  (`0100E95004038000_build/logs/`), the APK and the data folder. Delete `work/` to free the space; your files in
  `put-game-files-here/` are not touched.
- On the device: `Android/data/org.nx2a.t0100e95004038000/files/`. `log.txt` is the current run's log, `log.prev.txt`
  the previous one, `saves/` the game's saves, `settings.txt` the pause menu's choices.

## When something goes wrong

- **A black screen right after opening**: wake the device, close the game and open it again.
- **No sound, or the game closes at the first video**: the engine commit is not the tested one. Without `NX2A_DIR`,
  delete `work/nx2android` and run again.
- **Frames drop or the device gets hot**: lower the Resolution row, or use the device's standard performance mode.
- **Reporting a problem**: name the device, its Android version and the driver, and attach `log.txt` and
  `log.prev.txt`. Never attach game files.
