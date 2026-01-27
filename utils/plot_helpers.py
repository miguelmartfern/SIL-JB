# SIL-JB/utils/plot_helpers.py

from bokeh.models import Arrow, NormalHead, VeeHead, Label

def style_math_axes(p, x_range, y_range, prolong_axes=[0.1, 0.1], margins=[0, 0, 0, 0.05], xlabel="t", ylabel=r"$$\tilde{x}(t)$$"):
    """
    Replica EXACTAMENTE el estilo 'setup_axes' de tu librería Matplotlib.
    
    Lógica portada:
    - prolong_axes: fracción de margen extra a añadir a los ejes.
    - margins: [left, right, bottom, top] en proporción al rango.
    - Margen Y: 20% abajo, 32% arriba (1.6 * 0.2).
    - Flechas: Cruzan TODA la ventana visual (de límite a límite).
    - Grosor: 1.5 pt.
    """
    # 1. Limpieza total
    p.outline_line_color = None
    p.grid.visible = False
    p.axis.visible = False

    # 2. CALCULO DE MÁRGENES (Idéntico a tu código original)
    x0, x1 = x_range
    span_x = x1 - x0
    x_margin = prolong_axes[0] * span_x # 20% margen X
    
    y0, y1 = y_range
    span_y = y1 - y0
    y_margin = (prolong_axes[1] + 0.15) * span_y if span_y > 0 else 1.0 # 20% margen base Y
    # Calculamos los límites VISUALES finales (La "Caja" completa)
    vis_x0 = x0 - x_margin
    vis_x1 = x1 + x_margin
    
    vis_y0 = y0 - y_margin
    vis_y1 = y1 + y_margin 

    # Aplicamos estos límites a la cámara de Bokeh
    p.x_range.start = vis_x0 - margins[0] * (vis_x1 - vis_x0)
    p.x_range.end = vis_x1 + margins[1] * (vis_x1 - vis_x0)
    p.y_range.start = vis_y0 - margins[2] * (vis_y1 - vis_y0)
    p.y_range.end = vis_y1 + margins[3] * (vis_y1 - vis_y0)

    # 3. Estilo de Flechas
    LINE_WIDTH = 1.5
    ARROW_SIZE = 10
    
    # Usamos VeeHead para imitar el mutation_aspect=0.8 (flecha afilada)
    # fill_color=black y line_color=black la hacen sólida
    arrow_style = VeeHead(size=ARROW_SIZE, fill_color="black", line_color="black")
    
    # --- EJE X ---
    # Dibujamos la línea desde el borde izquierdo visual hasta el derecho
    p.segment(x0=vis_x0, y0=0, x1=vis_x1, y1=0, color="black", line_width=LINE_WIDTH)
    
    # Inicio desplazado un pelín (0.01) para asegurar la dirección
    p.add_layout(Arrow(end=arrow_style, 
                       x_start=vis_x1 - 0.01, y_start=0, 
                       x_end=vis_x1, y_end=0))
    
    # Etiqueta t: Debajo de la flecha
    p.add_layout(Label(x=vis_x1, y=0, text=xlabel, 
                       text_font_style="italic", text_font_size="12pt",
                       anchor="bottom_left",
                       x_offset=-10, y_offset=7)) # Ajustada para no chocar con la punta

    # --- EJE Y ---
    # Dibujamos la línea desde el borde inferior visual hasta el superior
    p.segment(x0=0, y0=vis_y0, x1=0, y1=vis_y1, color="black", line_width=LINE_WIDTH)
    
    # Punta de flecha en el extremo superior visual (vis_y1)
    # Usamos NormalHead para un aspecto más estándar en vertical
    p.add_layout(Arrow(end=arrow_style, 
                       x_start=0, y_start=vis_y1 - 0.01, 
                       x_end=0, y_end=vis_y1))

    # Etiqueta Y: A la izquierda de la punta (para no chocar con la gráfica si es alta)
    # O a la derecha, según tu preferencia. En tu código original suele quedar a la izquierda o encima.
    p.add_layout(Label(x=0, y=vis_y1, text=ylabel, 
                       text_font_size="11pt",
                       anchor="top_left",
                       x_offset=12, y_offset=-3)) # A la derecha de la flecha

    return p