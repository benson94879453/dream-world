class_name UIColors
extends RefCounted

# Panel backgrounds
const PANEL_BG: Color = Color(0.09, 0.10, 0.12, 0.97)
const PANEL_BG_LIGHT: Color = Color(0.13, 0.14, 0.18, 0.98)
const PANEL_BG_DARK: Color = Color(0.11, 0.12, 0.16, 0.98)

# Panel borders
const PANEL_BORDER: Color = Color(0.84, 0.71, 0.40, 1.0)
const PANEL_BORDER_SUBTLE: Color = Color(0.42, 0.46, 0.52, 1.0)
const PANEL_BORDER_DIM: Color = Color(0.31, 0.34, 0.40, 0.96)

# Backdrop
const BACKDROP: Color = Color(0.03, 0.03, 0.04, 0.64)
const BACKDROP_LIGHT: Color = Color(0.03, 0.03, 0.04, 0.18)

# Text colors
const TITLE_COLOR: Color = Color(0.98, 0.94, 0.82, 1.0)
const BODY_TEXT: Color = Color(0.92, 0.93, 0.96, 1.0)
const MUTED_TEXT: Color = Color(0.72, 0.75, 0.80, 0.96)
const ACCENT: Color = Color(0.94, 0.82, 0.49, 1.0)
const SUCCESS: Color = Color(0.62, 0.92, 0.67, 1.0)
const COMPLETED_TEXT: Color = Color(0.58, 0.60, 0.64, 0.98)

# Entry / sub-panel
const ENTRY_BG: Color = Color(0.15, 0.16, 0.20, 0.96)
const ENTRY_SELECTED_BG: Color = Color(0.23, 0.19, 0.12, 0.98)
const ENTRY_SELECTED_BORDER: Color = Color(0.97, 0.84, 0.43, 1.0)
const ENTRY_COMPLETED_BG: Color = Color(0.12, 0.12, 0.14, 0.95)
const ENTRY_COMPLETED_BORDER: Color = Color(0.34, 0.34, 0.36, 0.92)

# Inventory / hotbar specific
const INVENTORY_PANEL_BG: Color = Color(0.14, 0.15, 0.18, 0.98)
const HOTBAR_PANEL_BG: Color = Color(0.13, 0.11, 0.09, 0.98)
const HOTBAR_PANEL_BORDER: Color = Color(0.69, 0.56, 0.33, 1.0)
const TOOLTIP_BG: Color = Color(0.12, 0.12, 0.12, 0.97)
const TOOLTIP_BORDER: Color = Color(0.95, 0.85, 0.42, 1.0)

# Tab button
const TAB_ACTIVE_BG: Color = Color(0.46, 0.32, 0.17, 1.0)
const TAB_ACTIVE_BORDER: Color = Color(0.94, 0.82, 0.49, 1.0)
const TAB_INACTIVE_BG: Color = Color(0.18, 0.19, 0.22, 1.0)
const TAB_INACTIVE_BORDER: Color = Color(0.39, 0.43, 0.50, 1.0)
const TAB_ACTIVE_TEXT: Color = Color(1.0, 0.96, 0.82, 1.0)
const TAB_INACTIVE_TEXT: Color = Color(0.88, 0.88, 0.88, 1.0)

# Progress bar
const PROGRESS_FILL: Color = Color(0.93, 0.77, 0.31, 1.0)
const PROGRESS_BG: Color = Color(0.19, 0.21, 0.26, 1.0)

# HUD panel (QuestTracker / Toast – more transparent)
const HUD_PANEL_BG: Color = Color(0.08, 0.09, 0.11, 0.82)
const HUD_PANEL_BORDER: Color = Color(0.82, 0.69, 0.42, 0.94)
const HUD_ENTRY_BG: Color = Color(0.12, 0.13, 0.17, 0.92)
const HUD_ENTRY_BORDER: Color = Color(0.28, 0.30, 0.35, 0.95)

# Toast
const TOAST_BG: Color = Color(0.08, 0.09, 0.11, 0.9)
const TOAST_BORDER: Color = Color(0.84, 0.71, 0.40, 0.96)
const TOAST_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.24)

# Quest tracker text
const QUEST_TITLE_COLOR: Color = Color(0.97, 0.92, 0.75, 1.0)
const QUEST_NAME_COLOR: Color = Color(0.93, 0.94, 0.97, 1.0)
const QUEST_PROGRESS_COLOR: Color = Color(0.79, 0.82, 0.88, 0.96)
const QUEST_COMPLETED_NAME_COLOR: Color = Color(1.0, 0.84, 0.0, 1.0)
const QUEST_COMPLETED_PROGRESS_COLOR: Color = Color(1.0, 0.91, 0.42, 1.0)

# Toast text
const TOAST_ACCEPTED_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const TOAST_COMPLETED_COLOR: Color = Color(1.0, 0.84, 0.0, 1.0)
const TOAST_TURNED_IN_COLOR: Color = Color(0.56, 0.93, 0.56, 1.0)

# Standard sizes
const MODAL_BORDER_WIDTH: int = 3
const MODAL_CORNER_RADIUS: int = 8
const SUBPANEL_BORDER_WIDTH: int = 2
const SUBPANEL_CORNER_RADIUS: int = 6
const HUD_BORDER_WIDTH: int = 2
const HUD_CORNER_RADIUS: int = 6


static func build_panel_style(bg_color_: Color, border_color_: Color, border_width_: int, corner_radius_: int) -> StyleBoxFlat:
	var stylebox_ := StyleBoxFlat.new()
	stylebox_.bg_color = bg_color_
	stylebox_.border_color = border_color_
	stylebox_.border_width_left = border_width_
	stylebox_.border_width_top = border_width_
	stylebox_.border_width_right = border_width_
	stylebox_.border_width_bottom = border_width_
	stylebox_.corner_radius_top_left = corner_radius_
	stylebox_.corner_radius_top_right = corner_radius_
	stylebox_.corner_radius_bottom_left = corner_radius_
	stylebox_.corner_radius_bottom_right = corner_radius_
	return stylebox_
