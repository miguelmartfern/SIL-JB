# Manual de Integración: Simuladores Interactivos (Panel/Pyodide) en Jupyter Book (MyST)

Este manual detalla cómo programar, compilar e incrustar una aplicación web de análisis de señales (usando Python, SymPy y Panel) dentro de un Jupyter Book (v2). El objetivo es que se ejecute íntegramente en el navegador del alumno mediante WebAssembly, sin requerir un servidor Python en producción, y que pueda publicarse fácilmente en GitHub Pages o UVaDoc como Recurso Educativo Abierto (REA).

## Requisitos Previos

Asegurarse de tener instalado el siguiente software en tu entorno local:

```bash
pip install panel bokeh sympy numpy jupyter-book
```

## Fase 1: Creación y Compilación de la Aplicación

### Paso 1.1: Organizar el directorio

En la raíz del proyecto (por ejemplo, `~/git/SIL-JB`), asegurarse de tener una carpeta para el código fuente (ej. `utils/`) y crear la carpeta pública donde MyST espera encontrar los recursos estáticos.

```bash
# Crear la carpeta de estáticos en la raíz del proyecto
mkdir -p public
```

### Paso 1.2: Escribir el código de la aplicación (Panel)

Crear o editar el script de la aplicación. Para este manual, usaremos el simulador básico de señales en utils/toy_app.py:

```python   
# utils/toy_app.py
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
```

### Paso 1.3: Compilar a WebAssembly (Pyodide)

Se Debe transformar este código Python en un paquete de recursos web (HTML, JS, Web Workers) para que se ejecute en el navegador. Compilarlo indicando como salida la carpeta public que sde creó en el paso 1.1:

```bash
panel convert utils/toy_app.py --to pyodide-worker --out public
```

Verificación: Comprueba que en la carpeta `public/` existen los archivos `toy_app.html` y `toy_app.js`.

## Fase 2: Configuración del Libro (MyST)

### Paso 2.1: Configurar `myst.yml`

El notebook donde vayas a insertar la app debe estar registrado en el índice (`toc`).
Nota Importante: No incluyas la configuración de carpetas estáticas aquí, ya que el copiado de la aplicación se realizará manualmente en la fase de publicación para garantizar su funcionamiento.

Abre el archivo `myst.yml` y asegúrate de que tiene esta estructura:

```yaml
version: 1
project:
  # ... (tus identificadores, título, etc.) ...
  toc:
    - file: content/001-index.ipynb
    # ... tus otros temas ...
    - title: Herramientas Interactivas
      children:
        - file: content/prueba_panel.ipynb

site:
  template: book-theme
  # ... opciones del sitio ...
```

### Paso 2.2: Incrustar la App en el Notebook

Abrir el notebook donde se quiere mostrar la aplicación interactiva (ej. `content/prueba_panel.ipynb`). Insertar una celda de tipo **Markdown** y añadir el `iframe`.

¡Atención a la ruta! Para que la aplicación cargue correctamente tanto en pruebas locales como en la subcarpeta de GitHub Pages (ej. `/SIL-JB/`), debes usar dos puntos y barra (`../`) para subir un nivel en el directorio:

```html
<iframe 
    src="../toy_app.html" 
    width="100%" 
    height="450px" 
    frameborder="0"
    style="border: 1px solid #ccc; border-radius: 4px;">
</iframe>
```

## Fase 3: Pruebas y Desarrollo en Local

Debido a las restricciones de seguridad (CORS) y al sistema de enrutamiento del servidor de desarrollo nativo de MyST, la forma más fiable de probar tu aplicación en local es separando el servidor web de la carpeta estática.

### Paso 3.1: Levantar un mini-servidor estático

Abrir una terminal nueva en la raíz del proyecto y servir exclusivamente la carpeta `public`:

```bash
python -m http.server 8000 --directory public
```

### Paso 3.2: Modificar temporalmente el Notebook para desarrollo

Volver a `content/prueba_panel.ipynb` y cambiar temporalmente la ruta del iframe para que apunte al puerto 8000 (o crear un nuevo bloque markdown):

```html
<!-- SOLO PARA DESARROLLO LOCAL -->
<iframe 
    src="http://localhost:8000/toy_app.html" 
    width="100%" 
    height="450px" 
    frameborder="0">
</iframe>
```

### Paso 3.3: Arrancar Jupyter Book

En la terminal de trabajo habitual, borrar la caché (para asegurar una compilación limpia) y arrancar el entorno:

```bash
jupyter-book clean .
jupyter-book start
```

Abrir el navegador en `http://localhost:3000`, dirigirse a la página y verificar que la aplicación interactiva funciona correctamente.

## Fase 4: Publicación en GitHub Pages

Cuando esté listo para publicar el material definitivo como Recurso Educativo Abierto (REA), se debe revertir la ruta de desarrollo y generar el sitio estático.

## Paso 4.1: Restaurar la ruta de producción en el Notebook

Abrir `content/prueba_panel.ipynb` y volver a dejar la ruta relativa absoluta para la web compilada:

```html
<!-- RUTA PARA PRODUCCIÓN / GITHUB PAGES -->
<iframe 
    src="../toy_app.html" 
    width="100%" 
    height="450px" 
    frameborder="0"
    style="border: 1px solid #ccc; border-radius: 4px;">
</iframe>
```


Guardas el notebook.

### Paso 4.2: Compilar el sitio estático

Borrar la caché y generar los archivos HTML finales indicando la ruta del repositorio en GitHub para que los estilos carguen correctamente:

```bash
jupyter-book clean .
BASE_URL=/SIL-JB jupyter-book build --html
# En PowerShell:
# $env:BASE_URL="/SIL-JB"; jupyter-book build --html
```

### Paso 4.3: Copiar los archivos de la aplicación
Forzar la copia de los archivos interactivos compilados desde tu carpeta public hacia la carpeta web final (`_build\html`):

```bash
Copy-Item -Path "public\*" -Destination "_build\html\" -Recurse
```
### Paso 4.4: Despliegue con ghp_import

Por último, utilizar Python para subir la web compilada directamente a tu repositorio público (origin) en una rama de despliegue específica si se desea (ej. `rama-pruebas-panel-web`).
Nota: Se usa guion bajo (ghp_import) para que Python reconozca el módulo correctamente.

```bash
python -m ghp_import -n -p -r origin -b rama-pruebas-panel-web -f _build/html
```

### Paso 4.5: Activar GitHub Pages en el repositorio (Primer despliegue)

Si es la primera vez que se publica el libro en tu repositorio, se le debe indicar a GitHub que genere y sirva la página web a partir de la rama de despliegue que se acaba de crear. Solo se tendrá que configurar esto una vez:

1. Entrar en la página de tu repositorio en GitHub.
2. Ir a la pestaña **Settings** (Configuración) en el menú superior.
3. En la barra lateral izquierda, buscar el apartado *Code and automation* y hacer clic en **Pages**.
4. En la sección **Build and deployment**, asegurarse de que la opción *Source* está configurada en **Deploy from a branch**.
5. Justo debajo, en el menú desplegable de *Branch*, seleccionar la rama a la que enviaste los archivos en el Paso 4.4 (por ejemplo, `rama-pruebas-panel-web` o `gh-pages`).
6. Pulsar el botón **Save**.

*Nota final:* En la pestaña **Actions** del repositorio se podrá ver el progreso del despliegue. Cuando el indicador esté en verde (suele tardar 1 o 2 minutos), el Jupyter Book interactivo estará publicado y accesible de forma pública.

### Paso 4.6: Visualización

Una vez finalizado, acude a las opciones de GitHub Pages en tu repositorio, selecciona el despliegue desde la rama `rama-pruebas-panel-web`, espera unos instantes, y recarga tu web pública con `Ctrl + F5`.