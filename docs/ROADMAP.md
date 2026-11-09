# Roadmap after the beta
1. **Beta feedback round (device matrix):** measure FPS/thermals on 5+ real mid-range phones; tune particles, bloom and `difficulty.json` from play data.
2. **Hand-made art pass:** replace procedural meshes with authored models; per-skin trails; core-specific backgrounds; animated logo.
3. **Audio pass:** composed music, per-phase layers, mix/master.
4. **Monetization (optional, opt-in only):** rewarded ads (double run crystals) via AdMob Godot plugin; cosmetic packs and "remove ads" via Google Play Billing /
   StoreKit. Keep a `MonetizationService` interface; beta keeps a no-op implementation. Needs: store accounts, SDK keys, consent flow (UMP/ATT), privacy policy.
5. **Services:** Play Games/Game Center leaderboards, cloud save (conflict-safe merge), analytics (consented).
6. **Content:** weekly challenges, more patterns/obstacles, seasonal skins, daily seed challenge, ghost of personal best.
7. **Quality:** localisation (UI strings are in code today), accessibility (colour-blind obstacle shapes, reduce-motion), tablet layouts, iOS release.
8. **Name/brand:** verify availability of "ORBIT SHIFT" (trademark, domain, Google Play, App Store) before publishing.
