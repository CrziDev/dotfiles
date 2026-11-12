hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Qt apps follow qt6ct/qt5ct + Kvantum (KvArcDark). GTK_THEME is deliberately not set.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- GTK4 defaults to Vulkan, and only the NVIDIA dGPU has a Vulkan driver here, so GTK4 apps
-- (swaync) woke it from sleep on first draw (~1.8s lag). GL renders on the AMD iGPU instead.
hl.env("GSK_RENDERER", "gl")
-- hyprshot saves here instead of ~/Pictures root
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
