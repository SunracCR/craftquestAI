# 6. Importar preguntas

Importar evita copiar pregunta por pregunta. Siempre hay una **Vista previa** antes de confirmar. Las preguntas se añaden al cuestionario que tengas abierto.

1. Abre el cuestionario (puede estar en borrador).
2. Toca **Importar preguntas**.

![Pantalla Importar preguntas con Excel, CQIF JSON y TXT](img/06-01-importar-preguntas.png)

## Desde Excel

1. Elige **Importar desde Excel**. El título es **Importar Excel**.
2. En **Paso 1 · Plantilla**, toca **Descargar plantilla Excel** y rellénala. Solo se admiten archivos `.xlsx` de hasta 5 MB.
3. Columnas: Pregunta, Tipo (incluye `image_choice` e `image_based_question`, sin los archivos de imagen), Opción A–E, Respuesta correcta (por ejemplo `B` o `A|C`), Puntos y Sección (opcionales).
4. En **Paso 2 · Tu archivo**, arrastra el archivo (**Arrastra tu archivo .xlsx aquí**) o toca **Elegir archivo**.
5. Cuando veas **Archivo listo para importar**, toca **Subir y revisar**.

![Importar Excel con la plantilla y un archivo listo](img/06-02-importar-excel.png)

> **Nota.** **Las imágenes no se importan desde el archivo.** La vista previa lo marca como **Imagen pendiente en la app**. Entras a cada pregunta y añades la imagen allí.

Si el archivo no es `.xlsx`: **Solo se admiten archivos .xlsx**. Si pesa demasiado: **El archivo supera el límite de 5 MB**.

## Desde CQIF JSON o TXT CraftQuest

En **Importar preguntas** elige el **Formato**:

- **CQIF JSON** si tienes un `.json` exportado de CraftQuest, un borrador de la IA u otra herramienta compatible con CQIF v2. El campo pide **Pega aquí el JSON CQIF v2 completo**.
- **TXT CraftQuest** si el archivo es texto con bloques `[QUIZ]` y `[QUESTION]`. Es más cómodo de editar a mano.

Pega el contenido en **Contenido** y toca **Procesar importación**. Si no estás seguro del formato, la ayuda dice: pega el contenido, elige el formato más parecido y usa **Normalizar con IA** para convertirlo a JSON antes de importar. Esa normalización consume créditos de IA.

## Revisar y confirmar

La **Vista previa** resume cuántas preguntas son válidas y cuántas tienen error, por ejemplo **3 válidas de 4 (1 con error)**. Cada error indica la fila: **Fila N: mensaje**.

1. Corrige el archivo si hay errores y vuelve a subirlo, o continúa solo con las válidas.
2. Toca **Confirmar e importar**.
3. La app confirma **N preguntas importadas**.

![Vista previa de importación con preguntas válidas y una fila con error](img/06-03-vista-previa-importacion.png)

Si el plan no da para todas, la vista previa avisa antes: **Tu plan {plan} permite hasta {max} preguntas por cuestionario**. Solo se importarán las que quepan. Si el cuestionario ya está lleno, **Confirmar e importar** no se puede usar.

> **Consejo.** Publica el cuestionario después de importar, no antes de revisar. Una pregunta con la respuesta mal marcada se practica tal cual.
