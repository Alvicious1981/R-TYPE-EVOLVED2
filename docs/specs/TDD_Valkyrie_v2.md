**PROYECTO VALKYRIE-VII**

**DOCUMENTO DE DISEÑO TÉCNICO**

TDD — Versión 2.0  ·  Arquitectura y Plano de Construcción

| Campo | Detalle |
| ----- | ----- |
| Motor | Godot Engine 4.4+ | GDScript con tipado estricto forzado |
| Backend de Renderizado | Forward+ (Vulkan) — clustering de luces y rendimiento GPU avanzado |
| Resolución Base | 1920×1080 (16:9) | Escala canvas\_items | Aspect keep |
| Pixel Art | Filter \= Nearest | Renderizado 2D pixel-perfect |
| Ultrawide (21:9) | Letterbox automático — sin ventajas de visión periférica |
| Versión del Documento | 2.0 — Arquitectura Definitiva |
| FPS Objetivo | 60 FPS estables en hardware de gama media-baja |

# **1\. Especificaciones Fundamentales y Pipeline de Renderizado**

Este TDD es la abstracción arquitectónica de los requisitos del PRD. Su objetivo es dictar las reglas de ingeniería subyacentes, estructuras de código y patrones de diseño en Godot Engine 4.4+. Actúa como el plano de construcción para los programadores, priorizando metodologías de acoplamiento débil, alto rendimiento (60 FPS estables) y escalabilidad para prevenir la deuda técnica.

## **1.1. Arquitectura Data-Driven — Clases Resource**

El juego utilizará una arquitectura impulsada por datos basada en la clase Resource de Godot. Esto evita instanciar escenas pesadas solo para leer variables, reduce el acoplamiento y permite editar el balance del juego desde archivos de datos sin tocar código.

| Clase Personalizada | Hereda de | Atributos @export | Responsabilidad |
| ----- | ----- | ----- | ----- |
| UpgradeData | Resource | id: String, cost\_scrap: int, icon: Texture2D, stat\_modifier\_dict: Dictionary | Base de datos atómica de la Tienda. Separa datos mercantiles de la lógica del personaje. |
| EnemyProfile | Resource | id: String, max\_hp: int, point\_value: int, projectile\_pattern: Array\[PatternStep\] | Modela la diversidad enemiga. Una única Enemy.tscn inyecta este recurso en \_ready() para adoptar estadísticas e IA. |
| LevelChunk | Resource | chunk\_scene: PackedScene, heat\_level\_req: int, spawn\_weight: float | Dicta qué bloques pre-esculpidos están autorizados según el Nivel de Calor activo. |
| WeaponStats | Resource | fire\_rate: float, damage: int, spread\_angle: float, projectile\_speed: float | Define parámetros de arma separados del script de la nave; modificable en tiempo real por upgrades. |
| ForceConfig | Resource | mode: ForceMode (enum), energy\_drain\_rate: float, bounce\_charge\_gain: float | Parametriza el comportamiento del Módulo Force según el protocolo activo. |

## **1.2. Convenciones de Nomenclatura y Estilo de Código**

| Elemento | Convención | Ejemplo |
| ----- | ----- | ----- |
| Clases y Nodos | PascalCase | EnemyDreadnought, BulletPoolManager, HitStopManager |
| Variables y Funciones | snake\_case | current\_health, fire\_rate, \_on\_timer\_timeout() |
| Constantes y Enumeradores | SCREAMING\_SNAKE\_CASE | MAX\_SPEED, BULLET\_POOL\_SIZE, ForceMode.DETACHED |
| Señales | snake\_case con prefijo descriptivo | health\_changed, enemy\_destroyed, boss\_phase\_entered |
| Recursos (.tres) | kebab-case | enemy-zangano.tres, upgrade-dash.tres |
| Escenas (.tscn) | PascalCase | EnemyBase.tscn, DreadnoughtKrakon.tscn |

| ℹ  Tipado Estricto Obligatorio Es obligatorio el uso de tipado estático en todo el código GDScript: var health: int \= 100, func take\_damage(amount: int) \-\> void:. El tipado mejora el rendimiento del motor, aprovecha el autocompletado del IDE y captura errores en tiempo de edición antes que en tiempo de ejecución. |
| :---- |

# **2\. Gestión de Memoria y Rendimiento — El Sistema Bullet Hell**

El mayor cuello de botella técnico de un shmup es la instanciación y destrucción de proyectiles. Usar add\_child() y queue\_free() para miles de balas por segundo destruirá el Garbage Collector de Godot y provocará micro-stutters que arruinarán la experiencia táctica. La solución arquitectónica es el Patrón Object Pool.

## **2.1. BulletPoolManager — Patrón Object Pool**

**Autoload:** BulletPoolManager es un Singleton global (Autoload) que se inicializa antes que cualquier escena de nivel.

* Inicialización: al cargar el nivel, pre-instancia 2,000 entidades de bala inactivas y las posiciona fuera del viewport.

* Solicitud de bala: BulletPoolManager.get\_bullet(type: BulletType, pos: Vector2, dir: Vector2) \-\> Bullet

* Liberación de bala: al impactar o salir del viewport, la bala NO se destruye — desactiva colisiones, se oculta y retorna a la cola de disponibles.

* Separación por tipo: pools independientes para balas del jugador, balas enemigas estándar, y balas de jefe (patrón de ataque masivo).

| \# BulletPoolManager.gd extends Node const POOL\_SIZE: int \= 2000 var \_available: Array\[Bullet\] \= \[\] var \_active: Array\[Bullet\] \= \[\] func get\_bullet(type: BulletType, pos: Vector2, dir: Vector2) \-\> Bullet:     if \_available.is\_empty():         push\_warning('BulletPool exhausted — consider increasing POOL\_SIZE')         return null     var bullet: Bullet \= \_available.pop\_back()     bullet.initialize(type, pos, dir)     \_active.append(bullet)     return bullet func return\_bullet(bullet: Bullet) \-\> void:     bullet.deactivate()  \# Disable physics, hide, reset state     \_active.erase(bullet)     \_available.append(bullet) |
| :---- |

| ⚠  Umbral de Pool Exhausto Si el pool se agota durante los patrones de jefe (Fase 4 — Colapso Crítico), el sistema loguea un warning y descarta la solicitud en lugar de instanciar dinámicamente. Nunca se rompera el framerate por overflow de pool. Ajustar POOL\_SIZE en configuración de nivel si se detectan warnings frecuentes. |
| :---- |

## **2.2. Optimización Extrema — Servidores de Bajo Nivel de Godot**

Para los ataques definitivos de los Dreadnoughts (patrones de cientos de balas simultáneas en Fase 4), se descartará el uso de Nodos Area2D y Sprite2D estándar. La gestión se delegará directamente a los servidores de bajo nivel:

| Servidor | Uso | Beneficio |
| ----- | ----- | ----- |
| PhysicsServer2D | Colisiones circulares matemáticas para balas masivas de jefe — creación y destrucción directa de shapes sin nodos intermedios | Cero overhead de SceneTree; miles de cuerpos con mínimo coste de CPU |
| RenderingServer | Dibujado en batch de texturas de bala usando MultiMeshInstance2D — una sola draw call para cientos de instancias | Mínimo coste de GPU; evita el overhead de Sprite2D individual |

## **2.3. Presupuesto de Rendimiento por Sistema**

| Sistema | Presupuesto CPU (ms/frame) | Presupuesto GPU | Estrategia de Optimización |
| ----- | ----- | ----- | ----- |
| BulletPool (2000 balas activas) | \< 1.5 ms | Bajo (sprites 8×8 px) | Object Pool \+ colisión por bitmask |
| Física del Force (rebotes) | \< 0.3 ms | Mínimo | RayCast2D único \+ bounce vector matemático |
| IA enemiga (10-30 entidades) | \< 2.0 ms | Bajo | FSM ligera; actualización en FixedProcess cada 2 ticks para fodder |
| Shaders de hit flash | 0 ms CPU | Mínimo (toggle boolean) | GPU shader con uniform bool; cero cost en CPU |
| Chunks del nivel (culling) | \< 0.5 ms | Bajo (occlusion automático) | Object Culling Direccional; queue\_free() al salir del umbral X |
| Paralaje de fondo (4 capas) | \< 0.2 ms | Medio | Texturas atlaseadas; desplazamiento solo en Transform, no animación |

# **3\. Matriz de Colisiones — Capas y Bitmasks de Física**

Para reducir la sobrecarga de la CPU al mínimo posible, las colisiones deben estar estrictamente filtradas mediante la Matriz de Colisiones Binarias de Godot. Ninguna entidad comprueba colisiones contra capas irrelevantes. Esta configuración se establece en Project Settings y NO se modifica por código en tiempo de ejecución.

| Layer \# | Identificador | Escanea (collision\_mask) | Ignora | Notas |
| ----- | ----- | ----- | ----- | ----- |
| Layer 1 | Jugador\_Nucleo | Layer 3, Layer 4, Layer 6 | Todo lo demás | La micro-hitbox 4×4 px. Solo esta layer recibe daño del jugador. |
| Layer 2 | Municion\_Aliada | Layer 3, Layer 6 | Layer 4, Layer 5 (escudo Force no la absorbe) | Proyectiles del Wave Cannon y Vulcan. Nunca daña al jugador. |
| Layer 3 | Chasis\_Hostil | Layer 1, 2, 5 | Layer 4 (no se dañan entre ellos) | Cuerpo físico de todos los enemigos. Hit por munición aliada o Force. |
| Layer 4 | Municion\_Biomecanica | Layer 1, Layer 5 | Layer 2, Layer 3 | Balas enemigas. Solo hieren al jugador o son absorbidas por el Force. |
| Layer 5 | Modulo\_Tactico\_Force | Layer 3, 4, 6 | Layer 1, 2 | El Módulo Force. Rebota en terreno, daña enemigos, absorbe balas enemigas. |
| Layer 6 | Terreno\_Solido | — | Todo (estático) | Geometría de nivel. Bloquea movimiento del jugador y rebota el Force. |

| ℹ  Regla de Oro de Colisiones Nunca usar collision\_layer \= 0b111111 (todas las capas). Cada entidad debe declarar explícitamente su layer y mask. Una colisión no declarada es una colisión que nunca ocurre — mejor el rendimiento que la comodidad del código descuidado. |
| :---- |

# **4\. Topología del Nivel — Generación Procedimental (LevelManager)**

La ilusión del avance horizontal continuo es una técnica matemática sustentada por el EnvironmentManager. La cámara principal (Camera2D) es estática en la pantalla — es el mundo quien se mueve.

## **4.1. Mecánica de Desplazamiento**

* Todo el escenario está anclado al nodo raíz WorldRoot que mueve su coordenada X negativamente cada física tick (\_physics\_process(delta)).

* La velocidad de desplazamiento es configurable por bioma y se incrementa linealmente en Protocolo Nivel 2 (Aceleración de Deriva \+15%).

* El jugador se mueve relativamente al WorldRoot, no a la pantalla absoluta, garantizando coherencia física.

| \# EnvironmentManager.gd extends Node2D var scroll\_speed: float \= 120.0  \# px/s base var \_heat\_multiplier: float \= 1.0 func \_physics\_process(delta: float) \-\> void:     position.x \-= scroll\_speed \* \_heat\_multiplier \* delta     \_cull\_offscreen\_chunks() func apply\_heat\_level(heat: int) \-\> void:     \_heat\_multiplier \= 1.0 \+ (0.15 \* (heat \- 1)) if heat \>= 2 else 1.0 |
| :---- |

## **4.2. Object Culling Direccional — Gestión de Chunks**

* El nivel se compone de Chunks: escenas pre-diseñadas de un ancho exacto equivalente al viewport (1920 px).

* Un sensor (Area2D) en el borde izquierdo de la cámara detecta cuando un Chunk supera el umbral X \<= \-1920.

* Ese Chunk se elimina (queue\_free()) y el LevelManager ensambla uno nuevo a la derecha del viewport actual.

* El LevelManager consulta el calor activo y los pesos de spawn (LevelChunk.spawn\_weight) para seleccionar el próximo Chunk con aleatoriedad ponderada.

* RAM constante: nunca más de 3 Chunks activos simultáneamente en memoria (el actual, el anterior parcialmente visible, el siguiente pre-cargado).

| Chunk en Cola | Estado en Memoria | Acción del LevelManager |
| ----- | ----- | ----- |
| Chunk N-1 (pasado) | Marcado para destrucción | queue\_free() al cruzar umbral izquierdo |
| Chunk N (activo) | Completamente instanciado | Procesamiento normal; enemies activos |
| Chunk N+1 (preparado) | Pre-instanciado fuera del viewport derecho | Listo para entrada — cero lag de instanciación |

# **5\. Patrones Estructurales — Jefes, IA y Físicas**

## **5.1. IA de Dreadnoughts — Máquina de Estados Finitos Jerárquica (HFSM)**

La IA de los Dreadnoughts utiliza un patrón de Máquina de Estados Finitos Jerárquica (HFSM). Cada estado encapsula su propio comportamiento de forma aislada, y las transiciones entre estados son completamente desacopladas de la lógica de combat stats.

### **Interfaz Base del Estado**

| \# State.gd — Clase base virtual para todos los estados de IA class\_name State extends Node signal transition\_to(state\_name: String) \# Llamado al entrar al estado func enter() \-\> void: pass \# Actualización de lógica por frame func update(delta: float) \-\> void: pass \# Actualización de física (colisiones, movimiento) func physics\_update(delta: float) \-\> void: pass \# Llamado al salir del estado — limpieza de recursos func exit() \-\> void: pass |
| :---- |

### **Estados del Dreadnought y Transiciones**

| Estado | Condición de Entrada | Comportamiento | Condición de Salida |
| ----- | ----- | ----- | ----- |
| Idle\_Entrada | Inicio del encuentro | Movimiento de entrada al viewport \+ animación de activación | Posición de combate alcanzada → Ataque\_Primario |
| Ataque\_Primario | Fase 1 activa | Patrones de barrera \+ láseres de barrido; baterías exteriores activas | HP \< 60% → Transicion\_Fase2 |
| Transicion\_Fase2 | HP \< 60% | Animación de daño estructural; pausa de patrones de 1.5 s | Animación completada → Ataque\_Asimetrico |
| Ataque\_Asimetrico | Fase 2 activa | Patrones adaptados a brechas del armazón; ventanas de ataque al núcleo | HP \< 25% → Transicion\_Fase3 |
| Transicion\_Fase3 | HP \< 25% | Explosión del armazón exterior; núcleo expuesto; pausa de 0.8 s | Animación completada → Nucleo\_Expuesto |
| Nucleo\_Expuesto | Fase 3 activa | Patrones de máxima densidad y velocidad; núcleo vulnerable directo | HP \<= 10% Y Protocolo \>= 3 → Colapso\_Critico |
| Colapso\_Critico | HP ≤ 10% \+ Protocolo 3+ | Tormenta balística caótica — máximo stress del bullet hell | HP \= 0 → Muerte\_Dreadnought |
| Reposo | Transición entre ataques | Sin disparos; permite al jugador reposicionarse brevemente | Timer expirado → estado de ataque siguiente |
| Muerte\_Dreadnought | HP \= 0 | Secuencia de explosión en cadena; liberación masiva de Chatarra | Secuencia completa → carga del siguiente Chunk |

## **5.2. Cinemática Vectorial del Módulo Force**

Cuando el Módulo Force está en estado DETACHED (Despliegue Autónomo), utiliza matemáticas cartesianas puras para calcular rebotes físicamente coherentes que conservan la inercia.

| \# ForceModule.gd — Física de rebote en Despliegue Autónomo extends Area2D @onready var raycast: RayCast2D \= $RayCast2D var velocity: Vector2 \= Vector2.ZERO var current\_mode: ForceConfig.ForceMode \= ForceConfig.ForceMode.DETACHED func \_physics\_process(delta: float) \-\> void:     if current\_mode \!= ForceConfig.ForceMode.DETACHED:         return     \_check\_bounce()     position \+= velocity \* delta func \_check\_bounce() \-\> void:     raycast.target\_position \= velocity.normalized() \* 16.0     if raycast.is\_colliding():         var normal: Vector2 \= raycast.get\_collision\_normal()         velocity \= velocity.bounce(normal)         EventBus.force\_bounced.emit(position)  \# Para carga del Wave Cannon         \_generate\_radial\_shots() func \_generate\_radial\_shots() \-\> void:     for angle in range(0, 360, 45):  \# 8 proyectiles radiales         var dir := Vector2.RIGHT.rotated(deg\_to\_rad(angle))         BulletPoolManager.get\_bullet(BulletType.FORCE\_RADIAL, global\_position, dir) |
| :---- |

# **6\. Arquitectura de Interfaz de Usuario — MVC y Controles**

## **6.1. Separación MVC en la UI**

Para evitar que la interfaz esté fuertemente acoplada al nodo del jugador (lo que causaría errores si el nodo es destruido), se adopta un patrón pasivo Modelo-Vista-Controlador.

| Capa MVC | Responsabilidad | Implementación en Godot |
| ----- | ----- | ----- |
| Modelo | Estado del juego (HP, puntuación, energía del Force, chatarra) | RunManager y SaveManager como Autoloads; únicos propietarios del estado |
| Vista | Representación visual (barras, números, iconos) | HUD.tscn — CanvasLayer con Nodos Control únicamente. Sin lógica de juego. |
| Controlador | Conexión Modelo → Vista | HUD.gd escucha señales del EventBus: EventBus.player\_health\_changed.connect(\_on\_health\_update) |

Principio de aislamiento: el HUD nunca llama métodos del jugador ni accede a sus variables directamente. Si el nodo Player es destruido (muerte), el HUD sigue funcionando sin errores porque solo escucha señales globales.

## **6.2. Sistema de Input — Buffering y Remapeo**

* Todos los inputs se definen en el Input Map de Godot (Project Settings → Input Map) para permitir remapeo universal sin modificar código.

* Input Buffering para el Dash: las pulsaciones se almacenan en memoria durante 4 fotogramas (≈ 66 ms). Si el jugador presiona Dash un instante antes de terminar un estado de invulnerabilidad, el comando se ejecuta en cuanto es legal.

* Soporte de hardware agnóstico: teclado, gamepad XInput/DInput, hardware adaptativo — sin restricciones internas de tipo de dispositivo.

| \# InputBuffer.gd — Buffer de 4 frames para acciones de precisión class\_name InputBuffer extends Node const BUFFER\_FRAMES: int \= 4 var \_buffer: Dictionary \= {}  \# action\_name: int (frames restantes) func \_process(\_delta: float) \-\> void:     for action in \_buffer.keys():         \_buffer\[action\] \-= 1         if \_buffer\[action\] \<= 0:             \_buffer.erase(action)     if Input.is\_action\_just\_pressed('dash'):         \_buffer\['dash'\] \= BUFFER\_FRAMES func consume(action: String) \-\> bool:     if \_buffer.has(action):         \_buffer.erase(action)         return true     return false |
| :---- |

# **7\. Ecosistemas Independientes — EventBus y AudioManager**

## **7.1. EventBus — Acoplamiento Débil Global**

EventBus.gd es el Autoload central de comunicación. Todos los sistemas críticos se comunican exclusivamente mediante señales emitidas a través de él. Ningún script puede tener referencias directas a otros scripts de dominio distinto fuera de sus relaciones padre-hijo en la escena.

| \# EventBus.gd — Todas las señales globales del juego extends Node \# ── Jugador ── signal player\_health\_changed(new\_hp: int, max\_hp: int) signal player\_died() signal dash\_activated(direction: Vector2) signal iframes\_activated(duration: float) \# ── Force ── signal force\_mode\_changed(new\_mode: ForceConfig.ForceMode) signal force\_bounced(position: Vector2) signal force\_energy\_changed(value: float) \# ── Combate ── signal enemy\_destroyed(score\_value: int, scrap\_value: int, position: Vector2) signal boss\_phase\_entered(boss\_id: String, phase: int) signal boss\_damaged(position: Vector2, damage: int) signal critical\_explosion(position: Vector2, radius: float) \# ── Economía y Progresión ── signal scrap\_collected(amount: int) signal upgrade\_purchased(upgrade\_id: String) signal run\_ended(result: RunResult) |
| :---- |

| ℹ  Regla del EventBus Una señal solo se emite, nunca se 'llama' directamente a métodos de otro sistema. Si el sistema A necesita que el sistema B haga algo, emite una señal. Si el sistema B no existe, la señal simplemente no tiene receptores — sin crash, sin acoplamiento. |
| :---- |

## **7.2. AudioManager — Infraestructura de Polifonía Dinámica**

* El AudioManager mantiene un Pool de nodos AudioStreamPlayer (16 para SFX simultáneos, 2 para BGM con crossfade).

* Al solicitar un sonido (AudioManager.play\_sfx('explosion\_minor')), el gestor: busca un reproductor inactivo, lo enruta al bus correcto (SFX / BGM / UI / Ambient), reproduce y usa la señal finished para retornarlo al Pool.

* Prioridad de sonido: si todos los reproductores están ocupados, el nuevo sonido reemplaza al de menor prioridad definida en SoundPriority enum.

* Crossfade de BGM: al cambiar de área o fase de jefe, el AudioManager hace fade-out del tema actual (0.8 s) simultáneo con fade-in del nuevo tema, evitando cortes abruptos.

| Bus de Audio | Contenido | Efectos de Procesado |
| ----- | ----- | ----- |
| Master | Salida final | Limiter suave (-1 dB) para prevenir clipping en picos de explosión |
| BGM | Música FM sintetizada | EQ para realzar frecuencias de síntesis FM (800 Hz–4 kHz); reverb suave de sala |
| SFX\_Combat | Disparos, explosiones, impactos | Compresor ligero para consistencia; sin reverb (sonido directo y seco) |
| SFX\_UI | Clics de menú, alertas de HUD | Sin efectos; debe ser siempre claro e inteligible |
| SFX\_Ambient | Zumbidos de nave, sonidos de fondo de bioma | Filtro paso-bajo suave (\< 4 kHz) para que no compitan con SFX de combate |

# **8\. Arquitectura Roguelite — Progresión y Persistencia**

Para separar los datos efímeros de una partida (Run) de los datos permanentes del jugador, se implementan dos gestores distintos con responsabilidades estrictamente delimitadas.

## **8.1. RunManager — Estado Efímero de la Run Actual**

| Variable | Tipo | Descripción | ¿Persiste al morir? |
| ----- | ----- | ----- | ----- |
| current\_score | int | Puntuación acumulada en la run actual | No — se descarta |
| combo\_multiplier | float | Multiplicador de puntuación activo | No — se resetea |
| scrap\_collected | int | Chatarra recolectada en esta run | SÍ — se transfiere al SaveManager |
| active\_upgrades | Array\[UpgradeData\] | Mejoras temporales del Force adquiridas en esta run | No — se descarta |
| heat\_level | int | Nivel de Protocolo Omega activo | SÍ — persiste entre runs |
| run\_start\_time | int | Timestamp Unix del inicio de la run | No — estadística de sesión |

## **8.2. SaveManager — Estado Persistente y Anti-Cheat**

**Formato:** JSON serializado almacenado en user://save\_profile.dat mediante la clase FileAccess de Godot.

* Estructura del JSON: dos bloques principales — progression (Chatarra total, upgrades permanentes, Protocolos desbloqueados) y settings (preferencias de accesibilidad, configuración de audio, remapeo de controles).

* Guardado automático tras cada Pantalla de Resultado y tras cada compra en el Taller.

### **Integridad — Anti-Cheat Básico (SHA-256)**

Para prevenir manipulaciones simples del archivo de guardado que rompan la economía del juego, se implementa un sistema de verificación de integridad:

| \# SaveManager.gd — Verificación de integridad SHA-256 const SALT: String \= 'VALKYRIE\_INTEGRITY\_SALT\_v1'  \# Estático en código compilado func \_compute\_hash(json\_string: String) \-\> String:     return (json\_string \+ SALT).sha256\_text() func save\_profile(data: Dictionary) \-\> void:     var json\_str: String \= JSON.stringify(data)     var payload: Dictionary \= {         'data': json\_str,         'hash': \_compute\_hash(json\_str)     }     var file := FileAccess.open('user://save\_profile.dat', FileAccess.WRITE)     file.store\_string(JSON.stringify(payload)) func load\_profile() \-\> Dictionary:     var file := FileAccess.open('user://save\_profile.dat', FileAccess.READ)     var payload: Dictionary \= JSON.parse\_string(file.get\_as\_text())     if \_compute\_hash(payload.data) \!= payload.hash:         push\_error('Save file corrupted or tampered — resetting progress')         return \_get\_default\_profile()     return JSON.parse\_string(payload.data) |
| :---- |

| ⚠  Alcance del Anti-Cheat Este sistema previene modificaciones manuales simples del archivo JSON. NO es una solución anti-cheat de red — es protección de integridad local para preservar la economía del juego. Un atacante determinado con acceso al código fuente compilado puede recuperar el SALT. Para proyectos con tablas de clasificación online, se requerirá validación server-side. |
| :---- |

# **9\. Arquitectura de Game Feel — Sistemas de Retroalimentación Visual**

## **9.1. HitStopManager — Distorsión Temporal**

El HitStopManager es un Autoload que escucha señales críticas del EventBus y manipula Engine.time\_scale para crear micro-pausas que amplifican el impacto de los momentos de mayor peso mecánico.

| \# HitStopManager.gd extends Node func \_ready() \-\> void:     EventBus.boss\_damaged.connect(\_on\_boss\_damaged)     EventBus.critical\_explosion.connect(\_on\_critical\_explosion) func trigger\_hitstop(duration\_scaled: float, time\_scale: float) \-\> void:     Engine.time\_scale \= time\_scale     \# Usamos el tiempo REAL (process\_always) para salir del hitstop     await get\_tree().create\_timer(duration\_scaled, true, false, true).timeout     Engine.time\_scale \= 1.0 func \_on\_boss\_damaged(\_pos: Vector2, damage: int) \-\> void:     if damage \>= THRESHOLD\_HEAVY\_HIT:         trigger\_hitstop(0.05, 0.3) func \_on\_critical\_explosion(\_pos: Vector2, \_radius: float) \-\> void:     trigger\_hitstop(0.15, 0.05) |
| :---- |

| ℹ  Aislamiento de Nodos de UI del HitStop Todos los nodos de la UI (HUD, menús, pantallas de pausa) deben tener process\_mode \= Node.PROCESS\_MODE\_ALWAYS. Esto los hace completamente inmunes a la manipulación de Engine.time\_scale. El jugador siempre puede leer información crítica durante cualquier HitStop. |
| :---- |

## **9.2. Shaders — Hit Flash y Efectos Visuales**

| Shader | Tipo | Uniform Params | Activación |
| ----- | ----- | ----- | ----- |
| hit\_flash.gdshader | CanvasItem (Sprite2D material) | hit\_flash: bool, flash\_color: vec4 | Tween de 0.05 s vía EventBus.enemy\_destroyed |
| screen\_distortion.gdshader | ScreenSpaceEffect (WorldEnvironment) | distortion\_strength: float, distortion\_center: vec2 | Activado en explosiones críticas del Wave Cannon |
| grazing\_glow.gdshader | CanvasItem (Jugador Sprite) | glow\_intensity: float | Activado al entrar proyectil enemigo en radio de grazing (\< 8 px) |
| boss\_phase\_flash.gdshader | FullScreenOverlay | flash\_alpha: float, flash\_color: vec4 | Transición entre fases del Dreadnought — flash blanco de 0.1 s |

## **9.3. CameraShake — Temblores Orgánicos con Ruido de Perlin**

El CameraShake es un Component (nodo hijo de la Camera2D principal) que procesa ruido FastNoiseLite para generar temblores matemáticamente orgánicos y direccionales, reemplazando el movimiento aleatorio erróneo.

| \# CameraShake.gd — Temblor orgánico con FastNoiseLite class\_name CameraShake extends Node @onready var noise: FastNoiseLite \= FastNoiseLite.new() var \_trauma: float \= 0.0  \# 0.0 a 1.0 var \_noise\_time: float \= 0.0 const DECAY\_RATE: float \= 2.5 const MAX\_OFFSET: float \= 8.0 const NOISE\_SPEED: float \= 80.0 func add\_trauma(amount: float) \-\> void:     \_trauma \= minf(\_trauma \+ amount, 1.0) func \_process(delta: float) \-\> void:     if \_trauma \<= 0.0: return     \_noise\_time \+= delta \* NOISE\_SPEED     \_trauma \= maxf(\_trauma \- DECAY\_RATE \* delta, 0.0)     var shake\_amount: float \= \_trauma \* \_trauma  \# Suavizado cuadrático     get\_parent().offset \= Vector2(         noise.get\_noise\_1d(\_noise\_time) \* MAX\_OFFSET \* shake\_amount,         noise.get\_noise\_1d(\_noise\_time \+ 1000.0) \* MAX\_OFFSET \* shake\_amount     ) |
| :---- |

# **10\. Flujo de Escenas y Carga Asíncrona**

Las texturas atlaseadas de los jefes y los Chunks de nivel pueden tener un tamaño considerable. El cambio entre pantallas no puede congelar el juego ni cortar la música. Se implementa un sistema de carga en segundo plano con transición animada.

## **10.1. Pipeline de Carga Asíncrona**

| \# LoadingScreen.gd — Carga asíncrona con animación extends CanvasLayer var \_target\_scene\_path: String \= '' func load\_scene(path: String) \-\> void:     \_target\_scene\_path \= path     ResourceLoader.load\_threaded\_request(path)     \_animate\_intro()  \# Animación de entrada (fade, logo, etc.) func \_process(\_delta: float) \-\> void:     if \_target\_scene\_path.is\_empty(): return     var progress: Array \= \[\]     var status := ResourceLoader.load\_threaded\_get\_status(\_target\_scene\_path, progress)     \_update\_progress\_bar(progress\[0\] if not progress.is\_empty() else 0.0)     if status \== ResourceLoader.THREAD\_LOAD\_LOADED:         var scene: PackedScene \= ResourceLoader.load\_threaded\_get(\_target\_scene\_path)         get\_tree().change\_scene\_to\_packed(scene)  \# Cambio sin freeze |
| :---- |

* La BGM no se interrumpe durante la carga: el AudioManager opera en un proceso separado con PROCESS\_MODE\_ALWAYS.

* El hilo secundario de carga no comparte estado con el hilo principal de renderizado — sin condiciones de carrera.

* Si la carga falla (archivo corrupto o faltante), la LoadingScreen muestra un error amigable y retorna al Menú Principal sin crash.

## **10.2. Árbol de Escenas y Estructura de Proyecto**

| Directorio | Contenido | Notas |
| ----- | ----- | ----- |
| res://autoloads/ | EventBus.gd, BulletPoolManager.gd, AudioManager.gd, RunManager.gd, SaveManager.gd, HitStopManager.gd | Todos los Singletons del juego; se cargan antes que cualquier escena |
| res://scenes/entities/ | Player.tscn, Enemy.tscn, ForceModule.tscn, Bullet.tscn, Dreadnought\_\*.tscn | Escenas de entidades de juego; parametrizadas por Resource |
| res://scenes/levels/ | LevelBase.tscn, LoadingScreen.tscn, chunks/ | Escenas de niveles y directorio de Chunks pre-diseñados |
| res://scenes/ui/ | HUD.tscn, MainMenu.tscn, Workshop.tscn, ProtocolSelect.tscn, ResultScreen.tscn | Toda la interfaz de usuario — sin lógica de juego |
| res://resources/ | upgrades/, enemies/, weapons/, chunks/ | Todos los archivos .tres — base de datos de datos del juego |
| res://assets/ | sprites/, audio/, shaders/, fonts/ | Assets crudos; sprites importados con Filter=Nearest |
| res://scripts/ | State.gd, InputBuffer.gd, CameraShake.gd, FSM.gd | Clases de utilidad y patrones base sin escena asociada |

# **11\. Control de Versiones y Pipeline de CI/CD**

## **11.1. Configuración de Git y Git LFS**

* El archivo .gitignore incluirá la carpeta .godot/ y los archivos de importación generados automáticamente (\*.import).

* Git LFS (Large File Storage) rastreará: archivos de audio (.wav, .ogg, .mp3), texturas sin comprimir grandes (\> 512 KB), y atlas de sprites de jefes.

* Nunca commitear archivos binarios Godot sin LFS — collapse garantizado del repositorio en semanas.

| \# .gitattributes — Configuración Git LFS para assets pesados \*.wav filter=lfs diff=lfs merge=lfs \-text \*.ogg filter=lfs diff=lfs merge=lfs \-text \*.mp3 filter=lfs diff=lfs merge=lfs \-text \*.png filter=lfs diff=lfs merge=lfs \-text \*.webp filter=lfs diff=lfs merge=lfs \-text \*.tscn text eol=lf  \# Forzar LF en archivos de escena para compatibilidad cross-platform \*.gd text eol=lf    \# GDScript también con LF |
| :---- |

## **11.2. Convenciones de Commits y Branching**

| Tipo de Commit | Prefijo | Ejemplo |
| ----- | ----- | ----- |
| Nueva funcionalidad | feat: | feat: implement BulletPoolManager with 2000 entity cap |
| Corrección de bug | fix: | fix: force module velocity not resetting on re-attach |
| Optimización de rendimiento | perf: | perf: replace Area2D bullets with PhysicsServer2D for boss phase 4 |
| Refactorización sin cambio funcional | refactor: | refactor: extract FSM base class from DreadnoughtKrakon |
| Assets y recursos | assets: | assets: add sprite sheets for ZanganoFormation\_v3 |
| Documentación | docs: | docs: update TDD section 5 with HFSM transition table |
| Configuración del proyecto | chore: | chore: configure Git LFS for audio assets |

| Branch | Propósito | Reglas de Merge |
| ----- | ----- | ----- |
| main | Versión estable — solo builds testeados | Solo merge desde release/\* tras QA completo |
| develop | Integración de features en desarrollo | Merge frecuente de feature/\* branches |
| feature/nombre | Desarrollo de funcionalidades aisladas | PR con revisión mínima de 1 miembro antes de merge a develop |
| hotfix/nombre | Correcciones críticas en producción | Merge directo a main y develop simultáneamente |
| release/vX.X | Preparación de versión para distribución | Solo bugfixes; sin nuevas features; merge a main tras QA |

## **11.3. Checklist de Quality Assurance por Milestone**

| Check | Criterio de Aceptación | Herramienta / Método |
| ----- | ----- | ----- |
| Rendimiento base | 60 FPS estables con 2000 balas activas \+ 20 enemigos \+ Dreadnought en pantalla | Godot Profiler \+ GPU Monitor en hardware mínimo |
| Integridad del guardado | Hash SHA-256 detecta cualquier modificación del JSON de guardado | Test unitario automatizado con datos manipulados |
| Input buffer | Dash ejecutado dentro de 66 ms de buffer tras I-Frame es aceptado correctamente | Test de input con timestamp logging |
| Object Pool | Cero instanciaciones dinámicas de balas en sesión de 10 minutos de gameplay activo | Godot Memory Monitor — zero allocs de Bullet durante gameplay |
| Colisiones | Ninguna bala aliada daña al jugador; ninguna bala enemiga daña a enemigos | Test de colisión con mapa de bitmask verificado |
| Carga asíncrona | Cambio de escena sin freeze visual ni corte de BGM en hardware mínimo | Inspección visual \+ audio output monitoring |

**— FIN DEL DOCUMENTO TDD v2.0 —**