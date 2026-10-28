bar {
    status_command i3blocks -c ~/.config/i3/i3blocks.conf
    i3bar_command i3bar -t
    position top
    height 30
    font pango:Geist Mono 9
    colors {
        background {{ dark_background }}
        statusline {{ foreground }}
        separator {{ hairline }}
        focused_workspace  {{ hairline }} {{ hairline }} {{ bright_foreground }}
        active_workspace   {{ dark_background }} {{ dark_background }} {{ muted }}
        inactive_workspace {{ dark_background }} {{ dark_background }} {{ muted }}
        urgent_workspace   {{ red }} {{ red }} {{ bright_foreground }}
        binding_mode       {{ red }} {{ red }} {{ bright_foreground }}
    }
}

client.focused          {{ accent }} {{ dark_background }} {{ bright_foreground }} {{ accent }} {{ accent }}
client.focused_inactive {{ hairline }} {{ dark_background }} {{ muted }} {{ hairline }} {{ hairline }}
client.unfocused        {{ hairline }} {{ background }} {{ muted }} {{ hairline }} {{ hairline }}
client.urgent           {{ red }} {{ red }} {{ bright_foreground }} {{ red }} {{ red }}
client.background       {{ background }}
