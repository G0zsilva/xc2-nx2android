# Vulkan driver

Put one Turnip driver library (`libvulkan_freedreno.so`) in this folder. `setup.sh` packs it into the app, and the app
uses it instead of the device's own driver (it falls back to the device's driver if the library does not load).

The port was tested with **Mesa Turnip v27.0.0-20261114-r4, the A8xx build**, from
[The412Banner/Banners-Turnip](https://github.com/The412Banner/Banners-Turnip/releases/tag/v27.0.0-20261114-r4).
That build is for Snapdragon 8 Elite GPUs (Adreno 830 and its family). Download its zip, open it and copy
`libvulkan_freedreno.so` here. For another Adreno GPU, take the Turnip build made for it; that is untested.

With no file here the app uses the device's own driver. Qualcomm's driver ran the tutorial fight in an early build
(slower than Turnip), but it was not run again with the final fixes.

The `.so` files in this folder are ignored by Git: the driver is not redistributed here.
