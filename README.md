# Daredevil 2D — The Man Without Fear

Beat 'em up de acción, sigilo y plataformas en 2D desarrollado en **Godot Engine 4.7 (Renderizador Forward+)**, ambientado en el oscuro y descarnado universo cómic noir de **Hell's Kitchen**.

---

## 🎮 Controles de Juego

| Acción | Tecla / Entrada | Descripción |
| :--- | :--- | :--- |
| **Moverse** | `A` / `D` o `Flechas` | Desplazamiento horizontal |
| **Saltar** | `Espacio` | Salto de altura. Permite **Wall Jump** al rebotar contra muros |
| **Correr / Sprint** | `Shift Izquierdo` | Carrera rápida (habilitada en Modo Exploración, consume estamina) |
| **Agacharse** | `S` o `Flecha Abajo` | Agacharse para esquivar o golpear bajo |
| **Ataque / Combo** | `Z` | Combo cuerpo a cuerpo (4 golpes con puños o 3 con bastón) |
| **Patada Fuerte** | `X` | Patada horizontal contundente de alto empuje |
| **Bloquear** | `Click Derecho` | Guardia defensiva con bastón/brazos que absorbe impactos |
| **Cambiar Arma** | `C` | Alterna entre Puños (Arma 1), Bastón Corto (Arma 2) y Bastón Doble (Arma 3) |
| **Cambio de Postura** | `Q` | **Toggle**: Alterna entre **Modo Exploración** y **Modo Combate (Radar)** |

---

## 🌆 Pilares y Sistemas Implementados

### 1. Iluminación y Atmósfera 2D (Punto A)
- **Claridad y Contraste**: Iluminación ambiental nocturna calibrada vía `CanvasModulate` para que el jugador distinga claramente plataformas, puertas y edificios.
- **Farolas y Neones**: Sistema de `PointLight2D` con texturas radiales suaves sin banding, sombras suaves mediante `LightOccluder2D` y oclusores en los edificios.
- **WorldEnvironment**: Glow y Bloom optimizados para el renderizador Forward+ 2D de Godot 4.7.
- **Luz de Lectura de Matt**: Proyección suave de luz local centrada en Daredevil para que nunca se pierda en la penumbra.

### 2. Visión Acústica y Cambio de Postura (Punto B)
En lugar de una habilidad temporal con cooldown, la tecla **Q** conmuta instantáneamente entre dos posturas:
- **Modo Exploración (Default)**:
  - Movilidad ágil al 100%, sprint rápido y saltos fluidos.
  - Iluminación nítida del entorno para resolver puzzles y navegar por las azoteas.
- **Modo Combate / Radar Stance ("A World on Fire")**:
  - **Paleta Cómic Noir Estricta**: Blanco, gris, negro y rojo carmesí puro (`radar_world_fire.gdshader`).
  - **Detección de Siluetas**: Shader de contorno (`enemy_outline.gdshader`) con brillo acústico HDR sobre los ladrones para distinguirlos instantáneamente.
  - **Telegrafiado de Amenazas**: Alertas visuales (`!`) luminosas sobre los ladrones cuando preparan embestidas.
  - **Ventaja Ofensiva**: +30% de daño en todos los golpes y combos.
  - **Tradeoff**: Postura defensiva y metódica de boxeador, con velocidad controlada y **sprint deshabilitado**.

### 3. Game Feel & Juice (Punto C)
- **Screen Shake por Trauma** ([`scripts/camera_Daredevil.gd`](scripts/camera_Daredevil.gd)):
  - Sistema de sacudida cuadrática con ruido `FastNoiseLite`, calibrado proporcionalmente al impacto (0.12 en golpes ligeros, 0.45 en remates).
- **Hit-Stop / Freeze Frame** ([`scripts/hit_stop_helper.gd`](scripts/hit_stop_helper.gd)):
  - Micro-congelamiento de frames (`Engine.time_scale = 0.0`) al impactar (0.04s en puñetazos estándar, 0.08s en golpes pesados).
- **Knockback Diferenciado y Juggle Aéreo** ([`scripts/scriptLadron.gd`](scripts/scriptLadron.gd)):
  - Micro-stagger en golpes 1 y 2 (90 px/s), stagger medio en golpe 3 (180 px/s).
  - **Golpe 4 (Uppercut)**: Lanzamiento aéreo vertical (`velocity = Vector2(-dir * 260, -420)`) que permite mantener a los enemigos en el aire.
  - **Patada**: Empuje horizontal violento (450 px/s).
- **Hit Flash Blanco Puro**: Los enemigos destellan en blanco puro durante 0.05s al recibir daño antes de volver a su apariencia normal.
- **Coyote Time & Jump Buffer** ([`scripts/scriptDaredevil.gd`](scripts/scriptDaredevil.gd)):
  - Ventana de gracia de 120ms para saltar tras dejar una plataforma o antes de tocar el suelo.
- **Partículas VFX Autónomas (Noir)** ([`scenes/vfx/`](scenes/vfx/)):
  - [`hit_sparks.tscn`](scenes/vfx/hit_sparks.tscn): Chispas angulares contenidas (-70% sangre, blanco y carmesí sutil).
  - [`heavy_impact.tscn`](scenes/vfx/heavy_impact.tscn): Onda de choque expansiva limpia para remates pesados.
  - [`blunt_hit.tscn`](scenes/vfx/blunt_hit.tscn): Impacto contuso seco (100% monocromático, sin sangre) exclusivo para los ataques de los ladrones contra Daredevil.
  - [`dust_puff.tscn`](scenes/vfx/dust_puff.tscn): Polvo calibrado a la suela de las botas (`Y = +54px`) al saltar y aterrizar.

### 4. Sistema de Estamina, Guardia Táctica y Fatiga (Fase 1)
- **Fin de la Estamina Infinita**: Se eliminó la recarga rígida por frames. Ahora la energía se gestiona de forma continua con `delta` y pausas tácticas.
- **Stamina Recovery Delay**: Tras gastar energía, la barra no se recarga inmediatamente:
  - Modo Exploración: **0.8s** de delay (recarga a 32 pts/s).
  - Modo Combate: **1.2s** de delay (recarga a 24 pts/s).
- **Costes Calibrados**: Sprint sostenido (~5.5s continuos a 18.2 pts/s), salto regular (6 pts), wall-jump (12 pts), patada (20 pts base / 15 pts con radar), puñetazos (hits 1-3: 5 pts, hit 4: 8 pts), bastón (hits 1-2: 8 pts, hit 3: 15 pts).
- **Estado de Fatiga (Exhaustion)**: Al vaciarse la barra (0 pts), Matt sufre penalización de velocidad (-30%), no puede correr ni hacer wall-jump, y entra en respiración agitada continua (`BreathingFastSFX`) hasta recuperar al menos el **30%** de estamina.
- **Parry Perfecto & Guard Break** ([`scripts/scriptDaredevil.gd`](scripts/scriptDaredevil.gd)):
  - **Parry Perfecto**: Ventana de 0.15s al pulsar guardia (`blokear`). Anula el 100% del daño, devuelve **+25 pts de estamina**, **+10 pts de furia**, aplica freeze frame (0.08s), camera shake (0.20), sonido metálico agudo (`pitch 1.35`) y contra-stagger al enemigo atacante.
  - **Bloqueo Regular**: Consume estamina en proporción al golpe recibido (`max(damage * 0.8, 12)`), mitigando el 100% del daño a la vida.
  - **Guard Break**: Si la estamina no alcanza para absorber el golpe, la guardia se rompe: Matt sufre aturdimiento de 0.8s, retroceso, entra en fatiga forzada, SFX grave de rotura (`pitch 0.60`) y recibe un 25% de daño residual.
- **Momentum Refund**: Conectar el golpe 4 (Uppercut) reembolsa **+15 pts de estamina** para mantener el flujo de combate.

---

## 📁 Estructura del Proyecto

```
Daredevil2D/
├── assets/
│   ├── Audio/               # Efectos de sonido (golpes, pasos, latidos, respiración, guardia)
│   ├── lights/              # Texturas de luz radial, conos y WorldEnvironment
│   ├── shaders/             # radar_world_fire.gdshader, enemy_outline.gdshader
│   └── sprites/             # Sprites de Matt Murdock, ladrones, UI y VFX
├── docs/                    # Documentación de diseño y especificaciones técnicas
│   └── GDD_RADAR_SENSE.md   # GDD original de la mecánica de ecolocalización
├── scenes/
│   ├── daredevil.tscn       # Escena modular de Matt Murdock
│   ├── ladron.tscn          # Escena del enemigo básico
│   ├── hud.tscn             # Interfaz de usuario (Vida, Estamina, Furia, Stance)
│   ├── lvl_1.tscn           # Nivel 1 de Hell's Kitchen
│   └── vfx/                 # Escenas de partículas autónomas (HitSparks, HeavyImpact, etc.)
├── scripts/
│   ├── scriptDaredevil.gd   # Controlador de movimiento, estamina, fatiga, parry y combos
│   ├── scriptLadron.gd      # IA de enemigo, embestida, stagger y hit-flash
│   ├── camera_Daredevil.gd  # Cámara con seguimiento suave y trauma shake
│   ├── hitbox.gd            # Componente de daño y despacho de VFX
│   ├── health_component.gd  # Componente de vida con hook de intercepción de daño
│   └── hit_stop_helper.gd   # Helper seguro de micro-pausas
├── tests/
│   └── test_stamina_system.gd # Suite de pruebas automatizadas (24 tests unitarios)
├── Ideas.md                 # Documento vivo de diseño, mecánicas futuras y lore
└── project.godot            # Configuración de Godot 4.7 Forward+
```

---

## 🚀 Ejecución y Pruebas

### Requisitos
- **Godot Engine 4.7.2+** (Standard o .NET con soporte Forward+).

### Iniciar el Juego
Desde el editor de Godot o mediante terminal:
```bash
godot scenes/lvl_1.tscn
```

### Ejecutar Pruebas Automatizadas del Sistema de Estamina
```bash
godot --headless -s tests/test_stamina_system.gd
```

### Ejecutar Validación Headless de Escena
```bash
godot --headless scenes/lvl_1.tscn --quit-after 60
```
