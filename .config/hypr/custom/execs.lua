-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- SCREEN-SHARE FIX (START-02). xdg-desktop-portal's ScreenCast path needs
-- graphical-session.target, and that target sets RefuseManualStart=yes, so
-- nothing can start it directly. hyprland-session.service carries
-- Wants=graphical-session.target, so starting the unit is what pulls the target
-- up; that dependency edge is the only reachable path to it.
--
-- Start only, never `enable`: the unit is Type=oneshot with RemainAfterExit=yes,
-- so one start per session is enough, and staying in state `linked` keeps the
-- `systemctl --user disable` footgun (START-03, docs/dots-hyprland-workflow.md)
-- out of reach.
--
-- The call sits INSIDE the handler because it is a former `exec-once`: it must
-- fire once per session, not on every config reload. This handler coexists with
-- the vendor one at hyprland/execs.lua because hyprland.lua requires
-- custom.execs after hyprland.execs.
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprland-session.service")
end)
