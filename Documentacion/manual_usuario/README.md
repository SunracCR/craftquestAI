# Manual de usuario (PDF)

El manual está en `capitulos/`. Las capturas van en `img/` con el nombre que indica cada capítulo y [CAPTURAS_PENDIENTES.md](CAPTURAS_PENDIENTES.md).

## Qué imagen va en cada sitio

No eliges la página. El archivo se llama `CC-NN-descripcion.png`:

- `CC` es el número del capítulo (`05` = Mis cuestionarios).
- `NN` es el orden de esa figura dentro del capítulo.

Ejemplo: `05-04-detalle-cuestionario.png` es la cuarta figura del capítulo 5. La ficha de [CAPTURAS_PENDIENTES.md](CAPTURAS_PENDIENTES.md) dice la pantalla, el perfil, qué datos cargar antes y qué tiene que verse.

Si generas el PDF sin la foto, en ese hueco sale un recuadro **Captura pendiente** con el nombre del archivo. Guardas el PNG en `img/`, vuelves a generar y el recuadro desaparece.

`dist/capturas.html` repite las fichas en tarjetas. Puedes marcarlas mientras capturas. Al final lista los archivos de `img/` cuyo nombre no coincide con ninguno del manual.

## Generar el PDF

Hace falta Python 3.12 (o superior) y Microsoft Edge, que ya viene en Windows.

```powershell
py -3.12 -m pip install -r Documentacion/manual_usuario/requirements.txt
py -3.12 Documentacion/manual_usuario/build_manual.py
```

Si `py` no está en el PATH:

```powershell
& "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" -m pip install -r Documentacion/manual_usuario/requirements.txt
& "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" Documentacion/manual_usuario/build_manual.py
```

Resultados:

- `dist/CraftQuest_Manual_Usuario.pdf`
- `dist/manual.html` (el mismo documento, por si quieres revisarlo en el navegador)
- `dist/capturas.html`

Solo HTML, sin abrir Edge:

```powershell
py -3.12 Documentacion/manual_usuario/build_manual.py --html-only
```

La consola termina con `Capturas: N/M listas` y los nombres que faltan.

## Cómo tomar las capturas

1. Entra en [https://app.craftquestai.com](https://app.craftquestai.com) con una cuenta de prueba.
2. En Chrome: F12 → icono de teléfono → **iPhone 14** → captura el nodo de la página o la ventana.
3. En el teléfono, una captura de pantalla normal también sirve. Recorta la barra de estado si puedes.
4. Guarda el PNG con el nombre exacto de la ficha, en minúsculas, dentro de `img/`.
5. Vuelve a ejecutar `build_manual.py`.

No uses datos personales reales. Los diagramas de flujo no son capturas: el script los dibuja solo.
