# Xenoblade Chronicles 2 on Android (nx2android) — AYN Odin 3

Game profile and fixes to run **Xenoblade Chronicles 2** (title ID `0100E95004038000`, update 2.1.0) natively on Android with [nx2android](https://github.com/shirai91/nx2android), at 60 fps.

This repository **does not contain the game, keys or the driver**. You need your own dump of the game and your own keys.

## Results

Tested on the AYN Odin 3 (Snapdragon 8 Elite, Adreno 830, Android 15) with the Turnip driver.

| Item | Status |
|---|---|
| Boot, title, new game, the game's own save | Works |
| Fights and the town of Argentum at 1280x720 | 60 fps (frame time p95 16.9 to 17.6 ms, GPU ~10 ms) |
| Sound | Works |
| Videos (pre-rendered scenes) | Works (tested: the first video after the tutorial fight) |
| The port's pause menu | New rows: frame rate (30/60) and resolution |
| Later areas, long sessions, DLC | Not tested |

Known issue: the game closed once when it lost focus (opening the Odin's panel) in Argentum. It was not reproduced. Change the device's performance mode with the game closed.

## What is here

- `nx2android-xc2.patch` — fixes to nx2android's code, made on top of commit `9a89e76` of the original repository.
- `nxnative/dm/games/0100E95004038000/` — the game profile (configuration, executable patches and shader tables).

### What the patch changes

- **Sound:** in SDK 3.5.0 the audio render system sits at a different offset inside the renderer object; the port read the offset of newer SDKs and the game was silent (`hle_audren.c`).
- **Videos:** the game uses the older two-argument `movie::Decoder` constructor, which was not handled and crashed the game at the end of the first fight (`hle_movie.c`).
- **GPU on Turnip:** the depth workarounds written for Qualcomm's driver are now off when the driver is Turnip. On the title screen at 1280x720, GPU time went from 12.0 to 10.0 ms per frame (`gfx_vk_core.c`, `gfx_vk_exec.c`).
- **Per-queue raster origin:** fixes a flipped image (`nvn_obj.h`, `hle_nvn.c`, `nvn_mtl.*`, `gfx_null.c`, `gfx_vk_exec.c`).
- **Shaders:** a rule for compute shaders without a header (`shader_split.py`).
- **Pause menu:** frame rate and resolution rows (`overlay_layout.h`, `gfx_vk_present.c`, `front_android.c`, `loader.c`).

### What the profile does

- 60 fps through a patch to the game's frame step (30 fps in cutscenes), in `patches.py`.
- Replays the graphics commands on a thread of their own, pinned to the fastest core (`android.tsv`).

## How to use it

Requirements: a computer with Python 3, a dump of the base game and of update 2.1.0 (`.nsp` files), your `prod.keys`, an Android device with USB debugging on, and a Turnip driver for your GPU (`libvulkan_freedreno.so`). The tests used "Mesa Turnip v27.0.0-20261114-r4-A8xx".

1. Clone nx2android and check out the base commit:

   ```bash
   git clone https://github.com/shirai91/nx2android && cd nx2android && git checkout 9a89e76
   ```

2. Copy this repository's `nxnative` folder over nx2android's (it only adds the game profile) and apply the patch:

   ```bash
   git apply /path/to/nx2android-xc2.patch
   ```

3. Set up the Python environment as nx2android's README describes and put the game's `.nsp` files in a folder, for example `.gamedump/XenobladeChronicles2`.

4. Build the port:

   ```bash
   python -m porter port .gamedump/XenobladeChronicles2 --experimental -k /path/to/prod.keys --vulkan-driver /path/to/libvulkan_freedreno.so
   ```

5. Install it on the device:

   ```bash
   python -m porter install .gamedump/XenobladeChronicles2/XenobladeChronicles2-data
   ```

## Tips

- **A/B/X/Y feel swapped:** in the port's pause menu, Gamepad tab, the "Face buttons" row switches between mapping by position and by the button's letter.
- **Heat:** on the Odin 3, "Performance" mode keeps the GPU at its top clock all the time. In "Standard" mode the game held 60 fps in the fight tested, with the GPU at 660 MHz.
- **Resolution:** if frames drop, lower the resolution in the pause menu's "Resolution" row.

## Credits and notices

- [nx2android](https://github.com/shirai91/nx2android), by shirai91: the port itself is entirely their work; this is only this game's profile and a few fixes.
- Mesa Turnip: the open-source Vulkan driver for Adreno GPUs.
- Xenoblade Chronicles 2 is the property of Nintendo and Monolith Soft. Use it only with a copy of the game you own.
