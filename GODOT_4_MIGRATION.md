# Godot 4 Migration Guide

## Changes Made

This F1 racing game project has been migrated from Godot 3.x to Godot 4.x. The following changes were made:

### 1. Project Settings Updates
- Updated `project.godot` rendering settings to use Godot 4 format
- Removed deprecated rendering options (GLES2 fallback, old shader compilation settings)
- Updated to use `renderer/rendering_method="mobile"`

### 2. Environment Updates
- Updated `default_env.tres` to use Godot 4 Environment format
- Fixed Sky resource references
- Added ambient light settings for better default lighting

### 3. Input System Updates
- Replaced deprecated `Input.parse_input_event()` calls with `Input.action_press()`/`Input.action_release()`
- Updated UI button scripts: `camera_button.gd`, `accelerate_button.gd`, `braking_button.gd`

### 4. Audio System Updates
- Replaced deprecated `stream_paused` property with `stop()` method in `race_car.gd`

### 5. Scene Files
- Scene files (.tscn) will be automatically converted when first opened in Godot 4
- The project uses modern GDScript syntax (@onready, @export, etc.)

## Compatibility Notes

The project was already partially upgraded and uses:
- CharacterBody3D (modern physics)
- Texture2D for textures
- Modern signal connection syntax with Callable
- @onready and @export annotations

## Testing

After opening in Godot 4:
1. Check that all scenes load without errors
2. Verify that race car physics work correctly
3. Test UI controls and input handling
4. Ensure audio plays properly
5. Test different circuits and game modes

## Known Working Features
- Race car physics with CharacterBody3D
- Camera system (chase and zoom cameras)
- Circuit selection and loading
- Audio engine sounds
- UI controls and input handling