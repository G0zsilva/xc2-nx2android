# Third-party work

Nothing below is stored in this repository. `setup.sh` fetches or uses it on your computer.

| What | Where from | License | How it is used |
|---|---|---|---|
| nx2android (with nxnative, its engine) | [shirai91/nx2android](https://github.com/shirai91/nx2android), fetched from the fork branch that holds pull request 403 | MIT; the third-party code inside it keeps its own licenses | Does the whole port: extraction, rewriting, shader translation, the Android host, the APK |
| Mesa Turnip driver build | [The412Banner/Banners-Turnip](https://github.com/The412Banner/Banners-Turnip) | Mesa: MIT; the packaging repository: GPL-3.0 | You download it and put it in `drivers/`; it is packed into your APK |
| Android NDK, platform-tools | Google, downloaded by nx2android after you agree | Their own licenses | Building the host, installing over adb |
| .NET SDK | Microsoft, downloaded by nx2android after you agree | Its own license | Running the shader translator |
| The game | Your own dump | © Nintendo / MONOLITHSOFT | Read from `put-game-files-here/`; never stored or shared |
