# Agent test: can a small model draw a sheet from the docs alone?

Run after changing lib/sheets docs or components. Give a small model (Haiku)
this request with the rules below; it must write only in a scratch folder.
Judge: PDF on one page, number of runs, the difficulty log. Fix the docs for
every guess it had to make. History at the end.

Rules for the agent: do not modify the repo; write only in <scratch folder>;
read root CLAUDE.md and README.md first, then only what you need; keep a log
of every difficulty (what you looked for, errors, guesses). Reply with: PDF
and script paths, errors and runs, the log, files read, what you could not
do, suggestions.

Request 1 (Spanish, as the engineer writes):
"Necesito una lámina A2 horizontal para una estructura inventada (es una
prueba). 1. Planta de ubicación: ejes A, B, C, D en x (luces 4.50, 5.00, 4.50 m)
y ejes 1, 2, 3 en y (luces 5.00 y 4.00 m). Columnas de hormigón 30x30 en todos
los cruces, vigas de 25 de ancho por todos los ejes. Marca con una bola y
etiqueta los nudos B2 y C2. Agrega una barra de refuerzo adicional de 2Ø12,
L = 3000, sobre el eje 2 entre B y C. 2. Sección de la viga del eje 2: 25x40,
3Ø14 arriba y abajo, estribo Ø8 con ganchos a 135°, recubrimiento 4 cm, con
cotas. 3. Detalle de la conexión en B2: IPE 220 con placa extremo 130x240x12
en la cara de la columna, 4 varillas Ø16 (gage 80, filas a 40 y 190 desde
arriba), arandela y tuerca afuera; vista de frente de la placa con el perfil y
elevación con placa, grout de 25 y la varilla entrando 250 en la columna.
4. Tabla de cantidades y 4 o 5 notas. 5. Cajetín: proyecto PRUEBA, propietario
N/A, diseño estructural ING. PRUEBA, fecha OCTUBRE 2026, lámina 1/1."

## History
- 2026-10-10, run 1 (Haiku, 26 tool calls, ~5 min): good sheet in 3 runs
  (first came out on 2 pages, then a label overlap). Guesses and fixes made:
  printer choice and styles (-> STYLES.md, sheet_pdf), title block (-> sheet_pdf),
  dimension sign, bar diameter in plans, cells vs items, c_rc_section ct (->
  README Conventions), no front view of a nut (-> c_nut_front), silent page
  overflow (-> printer WARNING).
