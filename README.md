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

First enable supersampling — these options exist in upstream DXVK but are off by default:

```
d3d9.forceSampleRateShading = true
d3d11.forceSampleRateShading = true
```

Set the MSAA option in-game to choose the supersampling rate; MSAA is replaced with SSAA. If the game has no in-game MSAA setting, force it via `d3d9.forceSwapchainMSAA = 8` (or 2/4/8 for 2×/4×/8× supersampling).

These new options are added by this fork:

| Option | Default | Description |
|---|---|---|
| `d3d9.forceSwapchainMSAA` | `-1` | Forces an MSAA sample count on the D3D9 swapchain regardless of what the game requests. `-1` means no override. Set to `2`, `4`, or `8` to force 2×, 4×, or 8× supersampling on games that have no in-game MSAA option. |
| `d3d9.forceSampleRateShading` | `false` | Forces sample rate shading in D3D9 games, converting MSAA to SSAA (supersampling). Requires MSAA to be active (either in-game or via `forceSwapchainMSAA`). |
| `dxvk.transparentSkipSampleShading` | `true` | Disables per-sample shading on additive/multiplicative blend pipelines (glow, fire). Visually undetectable but eliminates framerate drops in glow-heavy scenes. |
| `dxvk.transparentShadingRate` | `1x1` | Variable Rate Shading rate for additive/multiplicative blend effects. `2x2` gives 4× fewer fragment invocations on glow draws at the cost of some blockiness on small distant effects. Options: `1x1` (off), `2x1`, `1x2`, `2x2`. Start with `2x2` and reduce if you see artifacts. |
| `dxvk.transparentMipBias` | `0.0` | Mip-LOD bias added to texture samples in glow/fire shaders. Pre-blurs textures to soften VRS block-boundary aliasing. Leave at `0.0` if `transparentShadingRate` is `1x1`. Typical range: `0.5`–`3.0`. |
| `dxvk.particleSkipSampleShading` | `false` | Same as `transparentSkipSampleShading` but for soft-alpha particle pipelines (smoke, dust, light shafts). Off by default — opt-in, as the particle classifier is heuristic. |
| `dxvk.particleShadingRate` | `1x1` | Same as `transparentShadingRate` but for soft-alpha particles. Smoke artifacts at `2x2` are visually distinct from glow artifacts — try `2x1` or `1x2` first. |
| `dxvk.particleMipBias` | `0.0` | Same as `transparentMipBias` but for soft-alpha particles. Leave at `0.0` if `particleShadingRate` is `1x1`. |
| `dxvk.particleSkipAlphaTested` | `false` | Extends particle optimizations to alpha-tested pipelines. Useful for D3D9 games where smoke/dust uses alpha-test as a discard-transparent shortcut (e.g. Freelancer). Disable if foliage or cutout edges look aliased. |

# Installation

Same as DXVK: Place the DLL for your game in the same directory as the games executable. If you are using Wine or Proton make sure that the dll is set as an override as `native,builtin` for the DLL.

You will need to know whether the game is 32 or 64 bit and which directx version the game uses. Then place the correct DLL in the game's directory.


# More info

See [dxvk](https://github.com/doitsujin/dxvk) for more info

