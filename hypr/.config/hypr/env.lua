hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Qt apps follow qt6ct/qt5ct + Kvantum (KvArcDark). GTK_THEME is deliberately not set.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- hyprshot saves here instead of ~/Pictures root
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
