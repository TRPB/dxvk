# Sync from upstream doitsujin/dxvk

Merge the latest commits from the upstream DXVK repo into this fork, update the dxbc-spirv submodule, and fix any conflicts. Follow these steps exactly.

## 1. Fetch upstream

`origin` is already set to `https://github.com/doitsujin/dxvk.git`:

```bash
git fetch origin
```

Check how many commits are incoming:

```bash
git log --oneline master..origin/master | wc -l
git log --oneline origin/master -10
```

## 3. Merge upstream master

```bash
git merge origin/master --no-edit
```

## 4. Resolve conflicts

Conflicts that can arise and how to handle each:

### README.md

This fork has a completely rewritten README. Any upstream README changes should be **discarded** — keep HEAD (our content) for the entire file. Do not let upstream sections bleed in.

### src/dxvk/dxvk_graphics.cpp

This fork adds VRS (Variable Rate Shading) support and a transparency classification system (`classifyTransparencyPass`). Common conflict points:

- **VRS pNext chaining**: We declare `VkPipelineFragmentShadingRateStateCreateInfoKHR vrsInfo` and chain it with `std::exchange`. If upstream changes the `VkGraphicsPipelineCreateInfo` initializer or surrounding pNext chain, keep our VRS struct declarations and chaining but adapt to the new upstream structure. VRS must only be chained when `wantsVrs` is true (it already is, gated by shading rate != 1x1).

- **`classifyTransparencyPass` and spec constant reads**: This function is entirely our addition. If upstream touches nearby code, keep the full function. It reads `state.sc.specConstants[0] & 0xf` for the d3d9 alpha compare op — verify this still matches `D3D9SpecData::alphaTest` bits 0..3 in `src/d3d9/d3d9_state.h` after any upstream spec constant rework. If the layout changes, update the dword index and bit mask to match.

### src/dxvk/dxvk_options.cpp / dxvk_options.h

This fork adds several options. Keep all of ours and add any new upstream options alongside them:
- `dxvk.transparentSkipSampleShading`
- `dxvk.transparentShadingRate`
- `dxvk.transparentMipBias`
- `dxvk.particleSkipSampleShading`
- `dxvk.particleShadingRate`
- `dxvk.particleMipBias`
- `dxvk.particleSkipAlphaTested`

### src/d3d9/d3d9_options.cpp / d3d9_options.h

Same principle — keep our options, merge in upstream additions.

### Other files

For any other conflict, prefer upstream's version unless the conflicting lines are part of our fork's feature additions (VRS, transparency classification, options). Check `git log --oneline origin/master..HEAD -- <file>` to see if we have our own commits touching that file.

## 5. Update the dxbc-spirv submodule

The submodule at `subprojects/dxbc-spirv` is our fork with one custom commit ("Enable sample rate shading override") on top of upstream.

If the merge leaves a submodule conflict:

```bash
# Check the common ancestor and what upstream wants
git -C subprojects/dxbc-spirv fetch https://github.com/doitsujin/dxbc-spirv.git main
git -C subprojects/dxbc-spirv merge-base HEAD FETCH_HEAD

# Rebase our custom commit onto upstream's new tip
git -C subprojects/dxbc-spirv rebase FETCH_HEAD
# If rebase stops at "staged changes", commit and continue:
#   git -C subprojects/dxbc-spirv commit -m "Enable sample rate shading override"
#   git -C subprojects/dxbc-spirv rebase --continue

# Stage the updated submodule pointer
git add subprojects/dxbc-spirv
```

After the main repo merge is committed, push the submodule to our fork:

```bash
git -C subprojects/dxbc-spirv push origin main --force
```

The force push is required because rebase rewrites the tip commit hash each time.

### Verify spec constant compatibility after submodule update

After rebasing the submodule, check whether the upstream dxbc-spirv changed how it exposes the alpha-test op to the IR. If `ir/passes/ir_pass_lower_io.cpp` changed significantly, review our "Enable sample rate shading override" patch to confirm it still applies cleanly and the sample rate shading override still works as expected.

## 6. Stage and commit

```bash
git add README.md src/dxvk/dxvk_graphics.cpp subprojects/dxbc-spirv
# add any other resolved files
git commit
```

## 7. Verify options after merge

After building, confirm these dxvk.conf options still behave correctly:
- `dxvk.particleSkipAlphaTested = false` — alpha-tested pipelines (foliage) should stay on per-sample shading
- `dxvk.particleSkipSampleShading` / `dxvk.transparentSkipSampleShading` — should skip sample shading only for their respective pass types
- `dxvk.transparentShadingRate` / `dxvk.particleShadingRate` — VRS should apply only to the targeted passes

## Key files owned by this fork

These files contain our additions — treat upstream changes to them with care:

| File | What we added |
|------|---------------|
| `src/dxvk/dxvk_graphics.cpp` | `classifyTransparencyPass`, VRS pNext chaining |
| `src/dxvk/dxvk_graphics.h` | `TransparencyClass` struct, related declarations |
| `src/dxvk/dxvk_options.cpp/h` | 7 new config options |
| `src/d3d9/d3d9_options.cpp/h` | Any d3d9-side option additions |
| `subprojects/dxbc-spirv` | Custom "Enable sample rate shading override" commit |
| `README.md` | Entirely rewritten for this fork |
| `.gitmodules` | dxbc-spirv URL points to TRPB fork |
