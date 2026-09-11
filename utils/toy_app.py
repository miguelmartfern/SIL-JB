import panel as pn
import bokeh.plotting as bkp
from bokeh.models import ColumnDataSource
import sympy as sp
import numpy as np

pn.extension(sizing_mode="stretch_width")

t = sp.Symbol('t', real=True)
expr_input = pn.widgets.TextInput(name="Señal x(t):", value="sin(2*t) + cos(t)")
status_text = pn.pane.Markdown("")
source = ColumnDataSource(data=dict(t=[], y=[]))

fig = bkp.figure(height=350, title="Señal interactiva", tools="pan,wheel_zoom,reset")
fig.line('t', 'y', source=source, line_width=2.5)

def update_signal(event=None):
    try:
        parsed_expr = sp.sympify(expr_input.value)
        f_num = sp.lambdify(t, parsed_expr, modules=["numpy"])
        t_vals = np.linspace(-5, 5, 500)
        y_vals = np.nan_to_num(f_num(t_vals), nan=0.0)
        if np.isscalar(y_vals):
            y_vals = np.full_like(t_vals, y_vals)
        source.data = dict(t=t_vals, y=y_vals)
        status_text.object = ""
    except Exception as e:
        status_text.object = f"Error: {str(e)}"

expr_input.param.watch(update_signal, 'value')
update_signal()

app = pn.Column(expr_input, status_text, fig)
app.servable()