# DXVK-supersampling

This is a fork of DXVK that adds some additional tweaks for supersampling (technically, sample rate shading!) in DXVK giving you a little more control over antialiasing options to tune visuals/performance.

DXVK already supports supersampling antialiasing via the little known option `forceSampleRateShading`. With multisampling enabled in-game it converts it to sample rate shading (effectively SSAA-SuperSampling Antialiasing) giving much better visuals.

For older games on newer hardware this looks fantastic but with a huge performance cost. At 3840x2160 my 7900XTX struggles with 8xSupersampling in some games. This fork of DXVK gives some tuning options to allow you to enable sample rate but selectively turn it off for parts of the scene that cause performance drops.

The biggest example is glow/fire/spell effects. These do not benefit from sample rate shading visually but incurr a huge performance cost as the supersampling has to be applied at each layer of transparency.

**Note: This is primarily designed for D3D9 games, for newer titles your mileage may vary.**

### What it does

When supersampling is enabled it: 

- Reduces significant FPS drops in games when there are a lot of glow/fire/particle effects on the screen
- Provides options for tuning how it does that

### Results

### 1. Freelancer (2003)

See the following screenshots. Framerate topleft. 

- glow effect [unpatched (75fps)](screenshots/freelancer-glow-vanilla.png) / [patched (175fps)](screenshots/freelancer-glow-patched.png) 
- smoke effect [unpatched (73fps)](screenshots/freelancer-smoke-vanilla.png) / [patched (181fps)](screenshots/freelancer-smoke-patched.png)


### What it does not do

- Improve general performance. These tweaks allow preventing supersampling from causing FPS drops, it does not improve overall game performance in scenes that do not have any transparent glow/fire/spell effects.


### AI Disclosure

This project was heavily AI assisted. It is designed to solve a very specific problem I have in older games I play regularly. Without AI it would have taken me far longer than I would have otherwise been willing to spend properly understanding all the nuances of 3d rendering.

### Relevant DXVK options for dxvk.conf

`d3d9.forceSampleRateShading = true` - Enable this to force sample rate shading in d3d9 games (this option exists in upstream DXVK but is off by default and needed for these tweaks to work) 
`d3d11.forceSampleRateShading = true` - Enable this to force sample rate shading in d3d11 games (this option exists in upstream DXVK but is off by default and needed for these tweaks to work) 

Set the MSAA option in game to set the supersampling rate, MSAA will be replaced with SSAA.

These new options have been added:

- `dxvk.transparentSkipSampleShading = true` *(default)* - Disables sample rate shading for transpacency/glow effects. Should be impossible to notice but can remove framerate drops entirely in glow heavy scenes
- `dxvk.transparentShadingRate = 1x1` *(default: 1x1 which is standard rendering behaviour identical to stock DXVK)* - Allows setting a different shading rate for glow effects, can improve performance in glow heavy scenes by a large amount (4x on the glow effects themeselves) but can also introduce visual artifacts on small glow effects distant from the camera. Available options: 2x2 (best performance), 1x2, 2x1. Recommended to start with 2x2 and then turn it down or off if you notice issues. Depending on screen resolution, game engine and upscaling settings may not have any visual impact at all but hugely improve performance.
- `dxvk.transparentMipBias = 0.0` *(default, disabled)* - Leave at zero if `transparentShadingRate` is 1x1 (off).
- `dxvk.particleSkipSampleShading = false` *(default, disabled)* - Same idea as `transparentSkipSampleShading` but applied to soft-alpha particles. Turn on if smoke effects tank your framerate.
- `dxvk.particleShadingRate = 1x1` *(default, disabled)* - Same as `transparentShadingRate` but for soft-alpha particles. Smoke artifacts at 2x2 look different from glow artifacts — recommended to start with `2x1` or `1x2` before trying `2x2`. Same opt-in caveats as the skip-sample-shading option.
- `dxvk.particleMipBias = 0.0` *(default, disabled)* - Same as `transparentMipBias` but for soft-alpha particles. Leave at zero if `particleShadingRate` is 1x1.
- `dxvk.particleSkipAlphaTested = false` *(default, disabled)* - Enabling this also enables sample rate shading for alpha tested pipelines. This is entirely game/game engine dependent. It will generally help performance with smoke/fog effects but it can also disable sample rate shading for foliage/leaves. Turning on will help performance but may need to be turned off if foliage looks bad.

# Installation

Same as DXVK: Place the DLL for your game in the same directory as the games executable. If you are using Wine or Proton make sure that the dll is set as an override as `native,builtin` for the DLL.

You will need to know whether the game is 32 or 64 bit and which directx version the game uses. Then place the correct DLL in the game's directory.


# More info

See [dxvk](https://github.com/doitsujin/dxvk) for more info

