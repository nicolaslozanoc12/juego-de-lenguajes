# Informe IEEE — El Cuatro Llanero

Esta carpeta contiene el informe del proyecto final de **Lenguajes de Programación**. El documento principal está escrito con la plantilla *IEEE Conference Template v1.1* (9 pt, dos columnas) y presenta el proyecto como un artículo: problema, solución, diseño formal, implementación y resultados.

## Contenido

| Archivo | Descripción |
|---|---|
| `main.tex` | Informe completo en LaTeX con formato IEEE. |
| `refs.bib` | Referencias bibliográficas de respaldo; el artículo integra las 17 entradas directamente en `main.tex`. |
| `INFORME.md` | Versión de lectura en Markdown, con los mismos contenidos y tablas. |
| `apendices_opcionales.tex` | Material de anexos separado del artículo: derivación, tabla de transición y traza completa. No se compila con `main.tex`. |
| `figuras/maquina_turing.png` | Máquina de Turing de tres cintas exportada de JFLAP. |
| `figuras/resultado_juego.png` | Captura de una partida en ejecución incluida en la sección de resultados. |
| `codigo/CuatroLlanero.g4` | Copia de la gramática del backend, incluida para trazabilidad. |
| `verificacion/verificar_tex.py` | Comprobaciones estructurales del `.tex` (entornos, citas, `\cref`, plantilla, figuras). |

La carpeta `verificacion/` conserva comprobaciones internas del repositorio que no forman parte del artículo; el informe no incluye mediciones ni una sección de pruebas.

## Cómo compilar `main.tex`

### Opción A: Overleaf (recomendada)

La plantilla oficial de IEEE SPS requiere `ieeeconf.cls` v1.1. Esa clase no se distribuye en este repositorio; se obtiene desde la plantilla oficial:

1. Abra <https://bit.ly/SPSpapertemplate> (IEEE Signal Processing Society Conference & Workshop Template).
2. Cree un proyecto nuevo con la plantilla o descargue su código fuente desde **Menu → Download → Source**.
3. En el proyecto, reemplace el `main.tex` de ejemplo por el `main.tex` de esta carpeta.
4. Suba `refs.bib` y la carpeta `figuras/`.
5. Compile con **pdfLaTeX**. La bibliografía ya está integrada en `main.tex`.
6. Compile normalmente con pdfLaTeX. Las referencias están integradas en `main.tex`, por lo que no requiere BibTeX ni el archivo `refs.bib`.

### Opción B: instalación local

Requiere una distribución de LaTeX (TeX Live o MiKTeX) con `ieeeconf.cls` v1.1. Copie `ieeeconf.cls` (y los archivos auxiliares de la plantilla, si los hay) junto a `main.tex` y ejecute:

```bash
pdflatex main
pdflatex main
pdflatex main
```

En un editor online, use **Recompile** o **Recompile from scratch**. No es necesario ejecutar BibTeX.

El documento usa `babel` (español), `tikz`, `graphicx`, `listings`, `booktabs`, `amsmath`, `bm`, `siunitx` y `cleveref`. Incluye diagramas TikZ, la imagen de JFLAP y una captura del videojuego.

### Estructura de la plantilla utilizada

`main.tex` respeta la interfaz de *IEEE Conference Template v1.1*:

- `\documentclass[9pt]{ieeeconf}` (cambie a `cameraready`, `singleanonymous` o `doubleanonymous` según el envío).
- Autores y afiliaciones con `\addauthor{...}{id}` y `\addaffiliation{id}{...}`.
- Agradecimientos en el entorno `acknowledgments`.
- Bibliografía integrada con `\begin{thebibliography}{00}`.
- `cleveref` configurado con `\crefname{equation}{}{}` para citar ecuaciones como «(3)».

El artículo no lleva apéndices: si el docente los pide, agregue al final de `main.tex`:

```latex
\appendix
\input{apendices_opcionales}
```

> Si la clase oficial entra en conflicto con `babel`, elimine la línea `\usepackage[spanish,es-noshorthands]{babel}` y compile; el texto sigue siendo correcto, aunque la hyphenación será la predeterminada.

## Qué debe reemplazar antes de entregar

- **Autores y afiliación:** las líneas `\addauthor{...}` y `\addaffiliation{...}` al inicio de `main.tex`. En `INFORME.md`, la cabecera correspondiente.
- **Agradecimientos:** el texto entre `\begin{acknowledgments}` y `\end{acknowledgments}`.
- **Universidad y ciudad:** Universidad de los Llanos, Villavicencio, Colombia.
- **Estado de la capa de presentación:** la sección 6.3 declara las limitaciones pendientes de entrada, audio y HUD. Actualícela cuando esas piezas estén integradas.

## De dónde sale el contenido

- **Gramática y lenguaje:** copia en `codigo/CuatroLlanero.g4`; el lenguaje generado se deriva analíticamente en la sección 3.
- **Máquina de Turing:** `figuras/maquina_turing.png`, exportada de JFLAP a partir de la función de transición del artículo. Las figuras se buscan en `figuras/` y en la carpeta principal para facilitar la compilación en editores online.
- **Traza del protocolo:** sección 4.6, con una petición y una respuesta completas.
- **Material de anexos:** `apendices_opcionales.tex`, por si se solicita como entrega aparte.
- **Referencias:** libros y artículos reales de teoría de autómatas, compiladores, diseño de juegos, generación procedural e IA para juegos, más la documentación oficial de ANTLR y JSON Schema.

Para comprobar la estructura del `.tex` desde la raíz del repositorio:

```bash
python Informe/verificacion/verificar_tex.py
```

## Estructura del informe

1. Introducción: gancho del contrapunteo, problema, pregunta de investigación, objetivos y contribuciones.
2. Marco teórico: gramáticas, analizadores y lenguajes específicos de dominio, máquinas de Turing, gramáticas y autómatas en la industria, juegos serios y JFLAP.
3. Lenguaje del juego: alfabeto, seis golpes, gramática, propiedades y tiempo real.
4. Arquitectura: dos capas, flujo de turno, reconocedor, máquina de Turing, combate y protocolo TCP.
5. Implementación: organización del núcleo.
6. Resultados: la máquina de Turing, coherencia del modelo y alcance.
7. Conclusiones: utilidad de gramáticas y autómatas en la industria del videojuego, y trabajo futuro.

Los anexos (derivación, tabla de transición y traza de una petición) quedaron fuera del artículo y se conservan en `apendices_opcionales.tex`.

## Nota académica

El artículo no incluye una sección de pruebas ni mediciones: su resultado es el modelo formal —la gramática, la máquina y su proyección en JFLAP— y el argumento de que esos objetos son infraestructura de producción en la industria. Las limitaciones se declaran en la sección 6.3.
