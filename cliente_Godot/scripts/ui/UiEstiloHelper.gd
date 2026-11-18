class_name UiEstiloHelper
extends RefCounted

## Helper compartido de estilos de botones para Menú Principal y Tutorial.


static func estilizar_boton(
	boton: Button,
	color_fondo: Color,
	color_borde: Color,
	color_texto: Color = Color(0.96, 0.96, 1.0)
) -> void:
	if not boton:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = color_fondo
	normal.border_color = color_borde
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color_fondo.lightened(0.16)
	hover.border_color = Color(1.0, 0.88, 0.42)
	hover.set_border_width_all(3)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color_fondo.darkened(0.18)
	pressed.border_color = Color(1.0, 0.94, 0.65)
	pressed.set_border_width_all(3)

	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", hover)
	boton.add_theme_stylebox_override("focus", hover)
	boton.add_theme_stylebox_override("pressed", pressed)
	boton.add_theme_color_override("font_color", color_texto)
	boton.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72))
	boton.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.72))
