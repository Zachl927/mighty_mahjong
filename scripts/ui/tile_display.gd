extends TextureButton
class_name TileDisplay

# Reference to the tile data
var tile_data: Tile = null

# Appearance properties
var highlight_color: Color = Color(1, 0.835, 0, 0.294)
var selected_color: Color = Color(0.2, 0.8, 1, 0.4)
var is_selected: bool = false
var is_highlighted: bool = false

# Signals
signal tile_selected(tile: TileDisplay)
signal tile_hovered(tile: TileDisplay)
signal tile_unhovered(tile: TileDisplay)

func _ready():
    set_focus_mode(Control.FOCUS_NONE)  # We'll handle our own focus
    # Set up the highlight node
    $Highlight.visible = false
    $Highlight.color = highlight_color

# Set the tile this display represents
func set_tile(p_tile: Tile):
    tile_data = p_tile
    if tile_data and tile_data.texture:
        texture_normal = tile_data.texture
    update_tooltip()

func get_tile() -> Tile:
    return tile_data

# Update the tooltip to show tile information
func update_tooltip():
    if tile_data:
        tooltip_text = tile_data.get_display_name()
    else:
        tooltip_text = "Unknown Tile"

# Highlight the tile when mouse enters
func _on_mouse_entered():
    if not is_selected:
        is_highlighted = true
        $Highlight.visible = true
        $Highlight.color = highlight_color
    tile_hovered.emit(self)

# Remove highlight when mouse exits
func _on_mouse_exited():
    if not is_selected:
        is_highlighted = false
        $Highlight.visible = false
    tile_unhovered.emit(self)

# Handle selection when clicked
func _on_pressed():
    toggle_selected()
    tile_selected.emit(self)

# Toggle selection state
func toggle_selected():
    is_selected = !is_selected
    
    if is_selected:
        $Highlight.visible = true
        $Highlight.color = selected_color
    else:
        if is_highlighted:
            $Highlight.color = highlight_color
        else:
            $Highlight.visible = false

# Force selection state
func set_selected(selected: bool):
    if is_selected == selected:
        return
        
    is_selected = selected
    
    if is_selected:
        $Highlight.visible = true
        $Highlight.color = selected_color
    else:
        if is_highlighted:
            $Highlight.color = highlight_color
        else:
            $Highlight.visible = false

# Apply visual effects (like animations, can be extended)
func apply_effect(effect_name: String, params: Dictionary = {}):
    match effect_name:
        "shake":
            var shake_amount = params.get("amount", 5.0)
            var shake_duration = params.get("duration", 0.5)
            
            # Create a simple shake animation
            var tween = create_tween()
            var start_pos = position
            
            # Multiple shake movements
            for i in range(10):
                var offset = Vector2(randf_range(-shake_amount, shake_amount), 
                                     randf_range(-shake_amount, shake_amount))
                tween.tween_property(self, "position", start_pos + offset, shake_duration / 10.0)
            
            # Return to original position
            tween.tween_property(self, "position", start_pos, shake_duration / 10.0)
            
        "highlight_flash":
            var flash_color = params.get("color", Color(1, 1, 0.5, 0.7))
            var flash_duration = params.get("duration", 0.6)
            
            # Save current state
            var was_highlighted = is_highlighted
            var was_selected = is_selected
            
            # Flash highlight
            $Highlight.visible = true
            $Highlight.color = flash_color
            
            # Return to original state after duration
            await get_tree().create_timer(flash_duration).timeout
            
            if was_selected:
                $Highlight.color = selected_color
            elif was_highlighted:
                $Highlight.color = highlight_color
            else:
                $Highlight.visible = false
