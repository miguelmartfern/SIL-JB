importScripts("https://cdn.jsdelivr.net/pyodide/v0.29.3/full/pyodide.js");

function sendPatch(patch, buffers, msg_id) {
  self.postMessage({
    type: 'patch',
    patch: patch,
    buffers: buffers
  })
}

async function startApplication() {
  console.log("Loading pyodide...");
  self.postMessage({type: 'status', msg: 'Loading pyodide'})
  self.pyodide = await loadPyodide();
  self.pyodide.globals.set("sendPatch", sendPatch);
  console.log("Loaded pyodide!");
  const data_archives = [];
  for (const archive of data_archives) {
    let zipResponse = await fetch(archive);
    let zipBinary = await zipResponse.arrayBuffer();
    self.postMessage({type: 'status', msg: `Unpacking ${archive}`})
    self.pyodide.unpackArchive(zipBinary, "zip");
  }
  await self.pyodide.loadPackage("micropip");
  self.postMessage({type: 'status', msg: `Installing environment`})
  try {
    await self.pyodide.runPythonAsync(`
      import micropip
      await micropip.install(['https://cdn.holoviz.org/panel/wheels/bokeh-3.8.2-py3-none-any.whl', 'https://cdn.holoviz.org/panel/1.9.4/dist/wheels/panel-1.9.4-py3-none-any.whl', 'pyodide-http', 'numpy', 'sympy']);
    `);
  } catch(e) {
    console.log(e)
    self.postMessage({
      type: 'status',
      msg: `Error while installing packages`
    });
  }
  console.log("Environment loaded!");
  self.postMessage({type: 'status', msg: 'Executing code'})
  try {
    const [docs_json, render_items, root_ids] = await self.pyodide.runPythonAsync(`\nimport asyncio\n\nfrom panel.io.pyodide import init_doc, write_doc\n\ninit_doc()\n\nimport panel as pn\nimport bokeh.plotting as bkp\nfrom bokeh.models import ColumnDataSource\nimport sympy as sp\nimport numpy as np\n\npn.extension(sizing_mode="stretch_width")\n\nt = sp.Symbol('t', real=True)\nexpr_input = pn.widgets.TextInput(name="Se\xf1al x(t):", value="sin(2*t) + cos(t)")\nstatus_text = pn.pane.Markdown("")\nsource = ColumnDataSource(data=dict(t=[], y=[]))\n\nfig = bkp.figure(height=350, title="Se\xf1al interactiva", tools="pan,wheel_zoom,reset")\nfig.line('t', 'y', source=source, line_width=2.5)\n\ndef update_signal(event=None):\n    try:\n        parsed_expr = sp.sympify(expr_input.value)\n        f_num = sp.lambdify(t, parsed_expr, modules=["numpy"])\n        t_vals = np.linspace(-5, 5, 500)\n        y_vals = np.nan_to_num(f_num(t_vals), nan=0.0)\n        if np.isscalar(y_vals):\n            y_vals = np.full_like(t_vals, y_vals)\n        source.data = dict(t=t_vals, y=y_vals)\n        status_text.object = ""\n    except Exception as e:\n        status_text.object = f"Error: {str(e)}"\n\nexpr_input.param.watch(update_signal, 'value')\nupdate_signal()\n\napp = pn.Column(expr_input, status_text, fig)\napp.servable()\n\nawait write_doc()`)
    self.postMessage({
      type: 'render',
      docs_json: docs_json,
      render_items: render_items,
      root_ids: root_ids
    })
  } catch(e) {
    const traceback = `${e}`
    const tblines = traceback.split('\n')
    self.postMessage({
      type: 'status',
      msg: tblines[tblines.length-2]
    });
    throw e
  }
}

self.onmessage = async (event) => {
  const msg = event.data
  if (msg.type === 'rendered') {
    self.pyodide.runPythonAsync(`
    from panel.io.state import state
    from panel.io.pyodide import _link_docs_worker

    _link_docs_worker(state.curdoc, sendPatch, setter='js')
    `)
  } else if (msg.type === 'patch') {
    self.pyodide.globals.set('patch', msg.patch)
    self.pyodide.runPythonAsync(`
    from panel.io.pyodide import _convert_json_patch
    state.curdoc.apply_json_patch(_convert_json_patch(patch), setter='js')
    `)
    self.postMessage({type: 'idle'})
  } else if (msg.type === 'location') {
    self.pyodide.globals.set('location', msg.location)
    self.pyodide.runPythonAsync(`
    import json
    from panel.io.state import state
    from panel.util import edit_readonly
    if state.location:
        loc_data = json.loads(location)
        with edit_readonly(state.location):
            state.location.param.update({
                k: v for k, v in loc_data.items() if k in state.location.param
            })
    `)
  }
}

startApplication()