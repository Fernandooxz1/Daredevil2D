# Daredevil2D — Documento de Ideas y Visión de Juego
**Documento Vivo de Diseño de Juego (GDD)**  
**Fecha de Actualización**: Septiembre 2026  
**Enfoque**: Filosofía de Diseño, Mecánicas de Oscuridad, Modos de Postura y Evolución Futura

---

## 1. La Visión Fundamental: "El Hombre sin Miedo en la Oscuridad"
En la mitología de Daredevil, Matt Murdock es ciego desde niño. Su "visión" no es un superpoder que se activa con un botón durante 5 segundos y luego se apaga: **es su estado natural**. Percibe el mundo a través del sonido, la resonancia, las corrientes de aire y los latidos del corazón de las personas ("Un Mundo en Llamas").

Por ende:
1. **La oscuridad es la aliada de Daredevil, no su enemiga**. Mientras que los matones y ladrones necesitan luz para ver y disparar, Matt se mueve con total soltura en la penumbra más absoluta.
2. **El jugador debe ver con claridad el entorno**: el juego debe ser legible, estético y permitir apreciar los detalles urbanos de Hell's Kitchen, mientras que las reglas de simulación del juego determinan qué pueden ver los enemigos y qué no.
3. **Los enemigos deben distinguirse al instante**: deben resaltar visualmente contra el asfalto, puertas y ladrillos con siluetas definidas y contornos acústicos.

---

## 2. El Bucle Central de Juego (Core Gameplay Loop)

```
┌────────────────────────────────────────────────────────┐
│ 1. INFILTRACIÓN Y PUZZLE (Modo Exploración)            │
│    Navegación ágil, sigilo, encontrar cajas de luz,    │
│    cortar cables y planificar la emboscada.           │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 2. "LUCES FUERA" (Blackout Táctico)                    │
│    Al cortar la electricidad, los enemigos quedan      │
│    a ciegas: visión reducida, pánico y puntería nula. │
│    Daredevil ve perfectamente en la oscuridad.         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 3. COMBATE Y EJECUCIÓN (Modo Combate / Radar Stance)   │
│    Cambio de postura a combate directo:                │
│    Daño demoledor, lectura de ataques y golpes letales.│
│    Tradeoff: velocidad controlada, sin sprint.         │
└────────────────────────────────────────────────────────┘
```

---

## 3. Sistema de Modos / Posturas (Stance Switch)
En lugar de una habilidad consumible con tiempo limitado y cooldown, la tecla **Q** actúa como un **cambio de postura táctico** entre dos estados según la situación:

### A. Modo Exploración / Percepción / Sigilo (Default)
* **Objetivo**: Movilidad fluida, exploración vertical de Hell's Kitchen y resolución de puzzles.
* **Movilidad completa**:
  * Velocidad estándar al 100%.
  * Sprint / carrera rápida habilitada (consumo normal de estamina).
  * Saltos de longitud y rebotes en pared (Wall-jump) ágiles.
* **Interacción**:
  * Interactuar con tableros eléctricos, interruptores, cables y puertas.
  * Localizar secretos y rutas alternativas por azoteas o conductos.
* **Estética visual**: Iluminación ambiental clara, tonos nocturnos urbanos nítidos y legibles.

### B. Modo Combate / Hiper-Concentración Sensorial (Radar Stance)
* **Objetivo**: Enfocar los sentidos al 100% en la biomecánica de los enemigos cercanos para dominar la pelea.
* **Ventajas en Combate**:
  * **Puntos Vitales**: Mayor daño en los combos de puños, bastón y patada (+30%).
  * **Anticipación Táctica**: Alertas visuales (`!`) inmediatas sobre los enemigos cuando preparan ataques fuertes o embestidas.
  * **Detección Acústica**: Siluetas de enemigos hiper-resaltadas en rojo/carmesí fluorescente que atraviesan obstáculos, paredes y gas.
  * **Ventana de Parry**: Bloqueos en el momento justo que aturden al rival sin drenar estamina.
* **Tradeoffs / Penalizaciones**:
  * **Velocidad de movimiento reducida** (~70% de la velocidad base): postura de boxeador/defensa cerrada, pasos calculados y metódicos.
  * **Sin Sprint rápido**: En hiper-concentración no corre desenfrenadamente; cada movimiento es táctico.

---

## 4. La Mecánica de Electricidad y Luces ("Blackout")

### El Concepto
Antes de entrar a una habitación o callejón con varios enemigos armados, el objetivo principal del jugador es **sabotear la iluminación**.

1. **Cortar la luz**: Romper un farol con el bastón arrojadizo, cortar un cable con un golpe o desactivar la caja de fusibles del edificio.
2. **Debuff masivo para los enemigos en la oscuridad**:
   * **Cono de visión reducido**: Pasan de ver a 450px a menos de 100px.
   * **Pánico y vacilación**: Se quedan quietos, apuntan a ciegas o fallan golpes con frecuencia.
   * **Vulnerabilidad a Takedowns**: Daredevil puede acercarse por la espalda o desde una cornisa y noquearlos instantáneamente.
3. **Ventaja asimétrica de Daredevil**:
   * Matt Murdock no usa los ojos; el apagón no reduce en nada su visibilidad acústica. El jugador sigue viendo todo el escenario con nitidez.

---

## 5. Evolución y Variedad de Enemigos (A Futuro)

Para que el sistema de luz y sombra no vuelva trivial el juego, se diseñarán tipos de enemigos con contramedidas:

| Tipo de Enemigo | Equipamiento | Comportamiento táctico |
| :--- | :--- | :--- |
| **Ladrón común** | Puños / Cuchillo | Muy vulnerable a la oscuridad. En penumbra entra en pánico y falla ataques. |
| **Matón con Linterna** | Linterna de mano / Foco de escopeta | Proyecta un cono de luz 2D direccional. En su cono ve normalmente y anula el debuff de oscuridad para sus aliados cercanos. Daredevil debe atacarlo por la espalda o romperle la linterna. |
| **Tirador / Francotirador** | Mira láser / Luz estroboscópica | Mantiene distancia y cubre pasillos iluminados. |
| **Enemigo con Bengalas** | Bengalas químicas / Luces de emergencia | Si se corta la luz, arroja bengalas al suelo que iluminan un área circular durante 10 segundos, restableciendo la visión de su grupo temporalmente. |
| **Guardias con Gafas Térmicas / Infrarrojas** | Dispositivos militares (minibosses) | Son capaces de ver a Matt incluso a oscuras; obligan a usar coberturas y combate cuerpo a cuerpo directo. |

---

## 6. Mejoras Visuales y de Legibilidad Inmediatas

1. **Iluminación Ambiental Clara (`CanvasModulate`)**:
   - Ajustar el modulate a un tono nocturno mucho más suave y luminoso (`Color(0.40, 0.43, 0.55)`). El escenario debe ser nítido, permitiendo apreciar puertas, ventanas y el arte de los edificios sin cansar la vista.
2. **Resaltado de Silueta de Enemigos (Enemy Silhouette Shader / Outline)**:
   - Crear un shader de contorno luminoso (*Outline*) para los ladrones.
   - En penumbra o en modo combate, el enemigo adquiere un reborde nítido (blanco/carmesí) que garantiza un contraste del 100% contra cualquier pared oscura.
3. **Aislamiento del HUD**:
   - Garantizar que el HUD permanezca con sus colores originales nítidos (barra verde, estamina amarilla, furia roja) sin ser teñido ni oscurecido por el ambiente ni por el modo combate.

---

## 7. Game Feel & Juice (Punto C Implementado)

Para que el combate y el movimiento se sientan viscerales, pesados y cinematográficos, se implementaron 6 sistemas clave de respuesta física y audiovisual:

1. **Screen Shake por Trauma en Cámara** ([`camera_Daredevil.gd`](file:///home/fernando/Work/Daredevil2D/scripts/camera_Daredevil.gd)):
   - Basado en el estándar de la industria (Squirrel Eiserloh): `trauma` cuadrático con decaimiento lineal (`decay = 2.5`) y variación de ruido `FastNoiseLite`.
   - Sacudida proporcional al golpe: 0.12 en golpes ligeros, 0.40 en patada y 0.45 en el Uppercut final.
2. **Hit-Stop / Freeze-Frame de Impacto** ([`hit_stop_helper.gd`](file:///home/fernando/Work/Daredevil2D/scripts/hit_stop_helper.gd)):
   - Micro-pausa del tiempo de juego (`Engine.time_scale = 0.0`) de 0.04s en puñetazos estándar y 0.08s en golpes demoledores (uppercut y patada), otorgando un peso brutal a cada conexión.
3. **Física de Knockback Diferenciada & Juggle Aéreo** ([`scriptLadron.gd`](file:///home/fernando/Work/Daredevil2D/scripts/scriptLadron.gd)):
   - Golpes 1 y 2: Micro-stagger (90 px/s).
   - Golpe 3: Stagger medio (180 px/s).
   - **Golpe 4 (Uppercut)**: Lanzamiento aéreo vertical (`velocity = Vector2(-direction * 260, -420)`), elevando al ladrón para rematarlo antes de que caiga.
   - **Patada**: Empuje horizontal violento (450 px/s).
   - Desaceleración suave física mediante `move_toward`.
4. **Hit Flash Blanco Puro** ([`enemy_outline.gdshader`](file:///home/fernando/Work/Daredevil2D/assets/shaders/enemy_outline.gdshader)):
   - Al recibir un impacto, el sprite del ladrón destella en blanco puro durante 0.05s antes de restaurar su silueta de cómic noir.
5. **Coyote Time y Jump Buffering** ([`scriptDaredevil.gd`](file:///home/fernando/Work/Daredevil2D/scripts/scriptDaredevil.gd)):
   - `coyote_time = 0.12s`: Permite saltar hasta 120ms después de caer de una cornisa.
   - `jump_buffer = 0.12s`: Recuerda la pulsación de salto 120ms antes de tocar suelo y ejecuta el salto en el instante del aterrizaje.
6. **Partículas Autónomas VFX Noir** ([`scenes/vfx/`](file:///home/fernando/Work/Daredevil2D/scenes/vfx/)):
   - [`hit_sparks.tscn`](file:///home/fernando/Work/Daredevil2D/scenes/vfx/hit_sparks.tscn): Chispas angulares cónicas blanco brillante y carmesí.
   - [`dust_puff.tscn`](file:///home/fernando/Work/Daredevil2D/scenes/vfx/dust_puff.tscn): Humo/polvo suave en pasos, aterrizajes y saltos.
   - [`heavy_impact.tscn`](file:///home/fernando/Work/Daredevil2D/scenes/vfx/heavy_impact.tscn): Onda de choque expansiva + estallido masivo para uppercut y patada.

---

## 8. Próximos Pasos de Implementación Recomendados

1. [x] **Ajuste de Iluminación y Visibilidad General**: Elevar la luz ambiente de `lvl_1.tscn` para que el entorno sea claro.
2. [x] **Shader de Resaltado para Enemigos**: Outline y silueta brillante en `Ladron` para distinción inmediata.
3. [x] **Conversión a Modo Postura (Toggle)**: Convertir la tecla Q en alternancia entre Modo Exploración (rápido) y Modo Combate (daño extra, siluetas, sin sprint).
4. [x] **Punto C (Game Feel & Juice)**: Screen shake por trauma, hit-stop, knockback con juggle, hit flash, coyote time y VFX 2D.
5. [ ] **Rediseño de Energía / Estamina**: Delay de regeneración, penalización por fatiga y recuperación activa por parry.
6. [ ] **Sistema de Cajas de Fusibles / Farolas Rompibles**: Objetos interactuables en el escenario que apagan luces puntuales y activan el estado ciego en enemigos.
7. [ ] **Desarrollo de Nivel Vertical**: Plataformas en azoteas, escaleras de incendio y cables tensores con coleccionables.
8. [ ] **Tipos de enemigos con linternas**: Conos de luz 2D que restauran la visión enemiga.

---

## 9. Desarrollo de Nivel, Plataformas y Recompensas Temáticas

### A. Plataformas Urbanas en Hell's Kitchen (Verticalidad)
El nivel actual es horizontal y de prueba. La atmósfera de Daredevil cobra vida al explotar la **verticalidad de Nueva York**:
* **Escaleras de Incendio de Hierro (Fire Escapes)**: Estructuras metálicas exteriores en los edificios que permiten ascender a cornisas y azoteas. Sonido metálico característico al pisarlas.
* **Cables Tensores y Tendido Eléctrico**: Cables entre edificios por los que Matt puede correr o equilibrarse para cruzar callejones sin tocar el suelo.
* **Torres de Agua (Water Towers) y Chimeneas**: Puntos de ventaja elevada ideales para observar rutas de patrulla enemigas o preparar emboscadas aéreas.
* **Andamios de Construcción y Vigas**: Plataformas semidestruidas donde el wall-jump es fundamental para no caer a callejones llenos de gas o enemigos armados.

### B. Recompensas y Coleccionables Temáticos (Lore de Daredevil)
En lugar de monedas genéricas, las recompensas deben reforzar la narrativa de abogado de día y justiciero de noche:

| Coleccionable | Tipo de Recompensa | Impacto en el Juego |
| :--- | :--- | :--- |
| **Evidencia Legal (Carpetas de Nelson & Murdock)** | Coleccionable Principal de Misión | Documentos incriminatorios de sobornos y lavado de dinero. Conseguir todas las carpetas de un nivel desbloquea el "Veredicto Judicial" (condena al capo del sector y otorga mejoras pasivas). |
| **Cintas de Casete / Grabaciones de Audio** | Audio-Logs Acústicos | Conversaciones clandestinas de la mafia. Matt detecta su origen en el radar mediante pulsos de sonido rítmicos. Al recogerlas, desbloquean diálogos y lore. |
| **Fichas de Metro Vintage (MTA Subway Tokens)** | Moneda de Intercambio Callejero | Antiguas fichas de bronce escondidas en respiraderos y callejones. Se utilizan para sobornar a informantes clandestinos (como Turk Barrett) a cambio de códigos de puertas o armas. |
| **Rosarios / Medallas del Padre Lantom** | Mejoras de Atributo | Reliquias de fe situadas en las alturas de campanarios y cornisas elevadas. Cada 3 rosarios aumentan la capacidad máxima de la barra de Energía o de Furia. |
| **Piezas de Bastón (Billy Club Parts)** | Mejoras de Equipo | Empuñaduras de titanio, cable de fibra retráctil o pesos de tungsteno que mejoran el alcance, daño o stagger de las armas 2 y 3. |

---

## 10. Rediseño del Sistema de Energía / Estamina

### Diagnóstico del Problema Actual
Actualmente, la barra de energía se recarga cada 3 ticks sumando +2 sin demora (`energy_regen_tick >= 3`). Esto produce una **estamina virtualmente infinita**: el jugador puede spamear sprints, combos y saltos sin gestionar recursos ni temer el agotamiento, anulando la tensión táctica.

### Propuesta de Rediseño Integral (Gestión Táctica y Tensión)

```
Acción (Sprint / Salto / Patada)
          │
          ▼
   Gasto de Estamina
          │
          ▼
┌──────────────────────────────────────────────────┐
│ STAMINA RECOVERY DELAY (0.8s - 1.2s de pausa)    │
│ La barra NO recarga mientras se siga accionando  │
└─────────────────────────┬────────────────────────┘
                          │ (Tras el delay sin gastar)
                          ▼
            Regeneración Suave Gradual (+30/seg)
```

1. **Delay de Recuperación (Recovery Delay)**:
   - Al realizar una acción que consuma energía, la regeneración se pausa por completo durante **0.8 segundos** (en Modo Exploración) o **1.2 segundos** (en combate). Solo cuando Matt deja de gastar energía comienza la recarga gradual.
2. **Costes Calibrados por Acción**:
   - **Sprint sostenido**: 18 puntos por segundo (agotable en ~5.5s de carrera continua).
   - **Wall Jump**: 12 puntos.
   - **Patada Contundente**: 20 puntos.
   - **Bloqueo Sostenido**: 8 puntos/segundo + drenaje por impacto recibido.
3. **Mecánica de Guard Break (Rotura de Guardia)**:
   - Si Daredevil bloquea un golpe sin suficiente estamina, sufre un **Guard Break**: la guardia se rompe con un chasquido metálico, sufriendo un stagger de 1 segundo de vulnerabilidad total.
4. **Estado de Fatiga (Exhaustion)**:
   - Si la barra llega a **0**, Matt entra en estado exhausto:
     - Imposible correr (sprint) ni realizar wall jumps.
     - Velocidad al caminar reducida en un 35%.
     - Audio activo de respiración jadeante (`BreathingFastSFX`) y latido sordo de advertencia.
     - No puede volver a correr hasta que la barra se recupere al menos al **30%**.
5. **Recuperación Activa por Habilidad (Skill-based Refund)**:
   - **Parry Perfecto**: Bloquear en los primeros 120ms del ataque enemigo no consume energía y devuelve **+25 de estamina** instantáneamente más un bono de furia.
   - **Remate de Combo (Uppercut Golpe 4)**: Conectar el golpe 4 completo devuelve **+15 de estamina**, premiando el flujo ofensivo.

---

## 11. Mecánicas Expandidas Propuestas para Discutir

* **Gancho de Bastón (Billy Club Grapple & Swing)**:
  - Lanzar el bastón con cable para engancharse a gárgolas, farolas o vigas altas, permitiendo balanceo estilo péndulo y takedowns aéreos.
* **Takedowns en la Oscuridad (Silent Stealth Finisher)**:
  - Si un enemigo está en estado ciego/pánico tras un apagón y Matt se aproxima sigilosamente por la espalda, ejecutar un noqueo silencioso instantáneo.
* **Distracción Acústica por Rebote**:
  - Arrojar el bastón contra una persiana metálica, barril o farol lejano para generar un foco acústico que desvíe a los patrulleros.
* **Detección de Frecuencia Cardíaca (Pulsómetro)**:
  - El latido del corazón de los ladrones acelera cuando sospechan o tienen miedo, indicando su nivel de alerta a través de la pared antes de abrir una puerta.

---

## 12. Estrategia de Arte y Sprites: Cómo Resolver la Falta de Dibujante

Uno de los mayores retos en el desarrollo indie es la creación de spritesheets coherentes y fluidos. Las IAs de imagen convencionales suelen fallar generando hojas de sprites consistentes (cambian la perspectiva, deforman el estilo y rompen la paleta). Para solucionar este obstáculo y ejecutar todas las ideas al 100%, aplicamos 4 técnicas estándar de la industria indie (como *Dead Cells*, *Celeste* o *Broforce*):

### 1. Mecánicas 100% por Código, Shaders y Audio (Cero Sprites Nuevos)
La mayoría de las mejores mecánicas no requieren nuevo arte dibujado, sino código y "juice":
* **Rediseño de Estamina & Fatiga**: Ya disponemos de las animaciones completas de caminar, correr, guardia, agacharse y el audio `BreathingFastSFX`. Todo el sistema se resuelve en `scriptDaredevil.gd` y `hud.gd`.
* **Rotura de Guardia (Guard Break)**: Reutiliza el frame de impacto/stagger existente del personaje, aplicando una vibración lateral rápida (`shake`) y un tintineo metálico (`blockedshield.mp3`).
* **Parry Perfecto**: No requiere animación nueva; se produce al conectar la guardia existente en el frame exacto, disparando el hit-stop, un destello blanco puro en el shader y un impacto seco.
* **Gancho y Cable del Bastón (Grapple & Swing)**: Se implementa con un nodo **`Line2D` procedural** de 2px de grosor (el cable) que une la mano de Matt con el punto de anclaje, rotando matemáticamente el sprite del bastón existente como gancho.
* **Apagones y Farolas**: Simplemente alternar `light.enabled = false`, hacer un sonido de cristal roto y spawnear chispas de `hit_sparks.tscn`.

### 2. Generación Programática de Pixel Art (Scripts en Python / PIL)
Para objetos pequeños y coleccionables (16x16 o 24x24 píxeles), las IAs generan manchas borrosas. En su lugar, podemos generar el pixel art exacto mediante scripts de Python (`Pillow`) dibujando cuadrículas de píxeles matemáticas con la paleta cómic noir estricta:
* **Carpeta de Evidencia**: Rectángulo manila/blanco de 16x12 con solapa roja y líneas grises de texto.
* **Cinta de Casete**: Carcasa gris oscuro de 18x12 con dos carretes blancos de 3x3 y cinta negra.
* **Ficha de Metro MTA**: Círculo de 14x14 en bronce/dorado oscuro con la letra "Y" troquelada en el centro.
* **Rosario / Medalla**: Cadena de cuentas de 1px con cruz blanca/plateada de 7x5.
* *Ventaja*: Son archivos PNG ultra-nítidos, con transparencia alfa perfecta y escala 1:1 sin deformaciones.

### 3. Animación Procedural y "Juice" en Godot (Motion Tweening)
Un coleccionable no necesita 30 frames de animación manual. Un único sprite estático de 16x16 adquiere vida profesional con técnicas de motor:
* **Flotación Senoidal**: Un script de 5 líneas que mueve `position.y += sin(time * 3.0) * 0.4` para que el objeto levite suavemente en el aire.
* **Sombra Proyectada**: Un elipse semitransparente oscuro en el suelo que escala de forma inversa a la altura del objeto.
* **Shader de Resplandor Acústico**: El mismo shader de contorno o un destello de brillo que pulsa al compás del latido de Matt en el modo radar.

### 4. Fuentes de Assets Libres y Kitbashing Modular
Para elementos de escenario (escaleras de incendio, andamios, cables):
* **OpenGameArt.org y Kenney.nl**: Cientos de paquetes de plataformas industriales y urbanas bajo licencia libre (CC0 / Dominio Público).
* **Kitbashing / Recorte de Spritesheets**: En la carpeta `assets/sprites/` ya existen texturas urbanas, fondos y edificios de donde se pueden recortar repisas, barandas y tuberías para componer nuevas plataformas sin dibujar desde cero.


