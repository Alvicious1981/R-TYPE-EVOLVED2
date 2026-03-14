**PROYECTO VALKYRIE-VII**

**DOCUMENTO DE REQUISITOS DEL PRODUCTO**

PRD — Versión 2.0  ·  Edición Definitiva Extendida

| Campo | Detalle |
| ----- | ----- |
| Género | Shoot 'em up (shmup) 2D de avance lateral horizontal |
| Plataformas Objetivo | PC (Windows / Linux / macOS) · Steam Deck · Consolas (futuro) |
| Motor de Juego | Godot Engine 4.4+ |
| Dificultad Objetivo | Alta — Bullet Hell con progresión Roguelite |
| Referentes Directos | R-Type, Gradius, DoDonPachi, Ikaruga |
| Versión del Documento | 2.0 — Edición Definitiva Extendida |
| Estado | En desarrollo activo |

# **1\. Resumen Ejecutivo y Visión General**

El proyecto es un videojuego del género Shoot 'em up (shmup) de avance lateral horizontal en dos dimensiones. El título está fuertemente arraigado en los principios de diseño de los clásicos de la era de 16-bits, tomando inspiración directa de franquicias como R-Type y Gradius. Su innovación radica en la integración profunda de un ciclo de progresión roguelite basado en carreras repetibles (runs) y un sistema de ascensión de dificultad modular y paramétrico.

El juego se distingue en el mercado por tres pilares diferenciadores fundamentales:

* Posicionamiento táctico de alta precisión, donde la micro-hitbox de la nave y la lectura de patrones son determinantes.

* Reconocimiento y evasión de patrones de ataque densos (Bullet Hell), exigiendo al jugador procesar cientos de proyectiles simultáneos.

* Dominio del Módulo Force: una entidad cibernética acoplable y balística que transforma radicalmente el combate según su configuración.

| ◆  Propuesta de Valor Única A diferencia de los roguelites contemporáneos que diluyen la dificultad con mejoras pasivas, este proyecto prioriza la maestría mecánica: la habilidad del jugador siempre pesa más que la acumulación de potencia estadística. La muerte es una herramienta de aprendizaje, no un muro de frustración. |
| :---- |

## **1.1. Objetivos Estratégicos del Producto**

| Objetivo | Métrica de Éxito | Prioridad |
| ----- | ----- | ----- |
| Retención a largo plazo | Sesión media \> 45 minutos en las primeras 2 semanas | Alta |
| Curva de aprendizaje controlada | 80% de jugadores superan el primer nivel en \< 10 intentos | Alta |
| Rejugabilidad sistémica | Tasa de runs repetidas \> 60% tras completar el juego | Media |
| Rendimiento técnico | 60 FPS estables en hardware de gama media-baja (GTX 1060 / RX 580\) | Crítica |
| Accesibilidad ampliada | Opciones de accesibilidad que no comprometan la mecánica central | Media |

# **2\. Narrativa, Mundo y Premisa**

La narrativa en los shmups tradicionales suele ser periférica. En este proyecto, sirve como marco justificativo para la estética opresiva y el ciclo de repetición roguelite, dotando de coherencia emocional y tonal a cada elemento de diseño.

## **2.1. Premisa y Universo**

**Contexto Global:** La humanidad ha sido diezmada. Civilizaciones enteras han caído ante la expansión implacable de la Alianza Biomecánica, una entidad cósmica parasitaria que asimila tecnología inerte y la fusiona con tejido orgánico alienígena. No existe defensa convencional ante una amenaza que aprende, evoluciona y se adapta en tiempo real.

**El Jugador:** El piloto de combate genéticamente modificado 'SCION-9', el último de su clase. Enlazado neuronalmente a la nave de asalto experimental 'Valkyrie-VII' mediante un interfaz sináptico directo, convirtiéndole en una extensión biológica de la máquina. No es un héroe: es la última apuesta desesperada de una civilización agonizante.

**La Misión:** Una incursión suicida hacia el Núcleo Central de la Alianza, el origen pulsante del que emana toda la expansión biomecánica. Destruirlo no es garantía de supervivencia — es simplemente la única opción que queda.

## **2.2. Justificación Narrativa del Ciclo Roguelite**

La naturaleza repetitiva del juego se fundamenta mediante el sistema de Transmisión de Conciencia Fragmentada (TCF). Al ser destruida la nave, los datos de combate acumulados, los patrones tácticos aprendidos y los recursos recolectados (Chatarra de Asimilación) se transmiten instantáneamente de vuelta a la Base Orbital Themis en el último microsegundo antes de la destrucción total.

Un nuevo clon de SCION-9 es ensamblado con la memoria táctica del anterior, permitiendo que cada fracaso contribuya directamente a la eficacia de la siguiente incursión. La muerte no es el fin: es la transferencia de información al siguiente intento.

## **2.3. Facciones y Entidades del Universo**

| Facción | Naturaleza | Rol en el Juego |
| ----- | ----- | ----- |
| Valkyrie-VII | Nave de asalto experimental de última generación, parte orgánica y parte máquina | Entidad controlada por el jugador |
| Alianza Biomecánica | Mente colmena cósmica que asimila tecnología y tejido orgánico | Facción enemiga principal |
| Zánganos | Drones fodder metálico-orgánicos de producción masiva | Enemigos comunes de baja amenaza individual |
| Torretas de Asimilación | Unidades estáticas adheridas a la geografía de los chunks | Control de zonas seguras |
| Dreadnoughts | Colosales naves jefe con subsistemas independientes destructibles | Jefes de sector con fases dinámicas |
| Base Orbital Themis | Última instalación humana funcional | Hub de mejoras inter-misiones |

## **2.4. Tono Emocional y Arco Narrativo**

* Tensión constante: el jugador siempre se siente en desventaja numérica y visual.

* Horror cósmico contenido: la amenaza es incomprensiblemente vasta, pero la escala se mantiene táctica y accionable.

* Catarsis explosiva: la tensión acumulada se libera violentamente a través de explosiones en cadena y destrucción masiva cuando el armamento optimizado entra en acción.

* Satisfacción de la maestría: cada run completada revela capas adicionales de profundidad mecánica, recompensando la inversión de tiempo con herramientas narrativas y mecánicas más ricas.

# **3\. Dirección de Arte, Sonido y Accesibilidad**

## **3.1. La Biblia Visual — Estética y Legibilidad**

La dirección de arte se construye sobre la tensión visual generada por el contraste extremo. El objetivo es evocar la nostalgia retro a través de técnicas de pixel art de alta fidelidad, asegurando simultáneamente que la legibilidad mecánica sea prístina y moderna. Cada decisión visual tiene una justificación funcional: el jugador debe poder procesar información crítica en milisegundos.

### **Paleta Cromática Dual**

| Facción Visual | Paleta de Colores | Propósito Funcional |
| ----- | ----- | ----- |
| Humanidad (Jugador) | Grises fríos, blancos inmaculados, azules metálicos radiantes | Elemento visualmente más limpio en pantalla; máxima legibilidad instantánea |
| Alianza Biomecánica | Rojos carnosos, púrpuras putrefactos, marrones oxidados, texturas dithering | Ambiente opresivo y orgánico; contraste máximo con la nave del jugador |
| Proyectiles Enemigos | Núcleo blanco puro \+ halos neón tóxicos (cian, magenta, naranja ardiente) | Procesamiento visual inmediato del peligro; nunca forman parte de la paleta del fondo |
| Módulo Force | Dorado metálico con destellos blancos en rebotes | Identificación táctica instantánea de la entidad aliada más importante |

### **Principios de Pixel Art**

* Resolución de trabajo: todos los sprites se crean a escala 1:1 en baja resolución y se escalan mediante multiplicadores enteros (×2, ×3, ×4).

* Técnica Dithering: tramado de píxeles en gradientes para simular volumen y profundidad con paletas de color limitadas, evocando las restricciones del hardware retro.

* Animaciones de 8-12 fotogramas por ciclo para movimientos principales; hasta 24 para explosiones y efectos especiales.

* Sprites de jefes: resolución interna de mínimo 128×128 píxeles antes de escalar, con partes destructibles animadas independientemente.

### **Reglas de Legibilidad en Combate Denso**

* Contraste de silueta obligatorio: todo proyectil enemigo debe tener una silueta reconocible a menos del 30% de brillo de pantalla.

* Jerarquía visual: jugador \> proyectiles enemigos letales \> enemigos \> terreno \> fondos de paralaje.

* Las capas de fondo nunca superarán el 60% de saturación para no competir visualmente con los elementos interactuables.

* Los puntos débiles de los jefes se señalizarán con pulsos lumínicos periódicos incluso en condiciones de pantalla saturada.

## **3.2. Dirección Sonora y Síntesis**

**Identidad Musical — Síntesis FM:** La banda sonora emulará el icónico sonido de los chips Yamaha OPL/OPN de los años ochenta mediante síntesis de Modulación de Frecuencia (FM). Esto proporciona líneas de bajo metálicas, percusiones industriales nítidas y arpegios rápidos que evocan tensión sin saturar las frecuencias medias reservadas para los SFX.

Cada área del juego tendrá un tema musical propio con variaciones dinámicas que responden al estado del combate:

* Exploración de nivel: ritmo moderado, capas de sintetizador atmosféricas.

* Oleada de enemigos intensa: introducción de percusiones industriales y líneas de bajo más agresivas.

* Fase de jefe: tema dedicado con estructura en tres actos que se intensifica conforme el jefe pierde HP.

* Fase crítica de jefe (10% HP): modulación abrupta hacia frecuencias más altas y tempo acelerado.

### **Asignación de Frecuencias para SFX**

| Rango de Frecuencia | Tipo de Sonido Asignado | Justificación |
| ----- | ----- | ----- |
| \< 150 Hz (Subgrave) | Impactos de jefes, Wave Cannon cargado, colisiones letales | Peso físico en momentos mecánicamente críticos; perceptible incluso en hardware de audio básico |
| 150–500 Hz (Grave) | Explosiones mayores de Dreadnoughts | Cuerpo de las explosiones grandes sin saturar otras bandas |
| 500–2000 Hz (Medio) | Disparos estándar Vulcan, Motor de nave, Alertas de UI | Rango de mayor presencia; sonidos frecuentes y de tracking continuo |
| 2000–8000 Hz (Agudo) | Explosiones menores, Chispas de impacto, Colisiones de Force | Crispness y definición; no compiten con la música FM |
| \> 8000 Hz (Muy agudo) | Grazing, Efectos de campo de escudo | Feedback instantáneo de precisión táctica |

## **3.3. Matriz de Accesibilidad y Confort**

Considerando la barrera de entrada de los shmups tradicionales, el producto implementa sistemas de accesibilidad que mitigan deficiencias visuales y motrices sin alterar el comportamiento central de las mecánicas. La accesibilidad no es opcional: es una característica de diseño de primer nivel.

| Característica | Descripción Funcional | Beneficio Directo | Prioridad |
| ----- | ----- | ----- | ----- |
| Visualización de Hitbox | Superposición de cuadrado brillante 4×4 px sobre el punto exacto de colisión de la nave y proyectiles enemigos (toggle en menú) | Elimina ambigüedad sobre qué colisiones causan daño real | Alta |
| Modo Alto Contraste | Filtro post-procesado: fondo al 30% saturación, entidades interactuables al 130% saturación | Identificación de amenazas para jugadores con impedimentos visuales | Alta |
| Remapeo Universal de Controles | Asignación completamente agnóstica de dispositivo; múltiples acciones por botón; hardware adaptativo sin restricciones | Mitiga barreras motrices y permite hardware especializado | Alta |
| Escalado Dinámico de UI | Redimensionamiento de elementos informativos entre 100% y 150% sin pérdida de resolución ni ocultamiento del campo de juego | Legibilidad en pantallas portátiles y usuarios con baja agudeza visual | Media |
| Mezclador de Audio Discreto | Deslizadores independientes: BGM, SFX Combate, Alertas UI, Sonidos Ambientales | Previene sobrecarga sensorial y permite depender de señales auditivas específicas | Media |
| Pausa Extendida | Capacidad de pausar durante cualquier fase de jefe con visualización de patrones activos congelados | Permite al jugador analizar situaciones sin presión temporal | Media |
| Modo Daltonismo | Reemplazo de paleta de proyectiles enemigos por formas/símbolos adicionales además del color | Accesibilidad para jugadores con deficiencias en la percepción del color | Media |

# **4\. Mecánicas de Juego Centrales (Gameplay Core)**

## **4.1. La Nave Valkyrie-VII — Sistema de Movimiento**

El sistema de movimiento es la interfaz primaria entre el jugador y el espacio de juego. Su respuesta debe ser inmediata, predecible y expresiva.

| Parámetro | Especificación | Notas de Diseño |
| ----- | ----- | ----- |
| Velocidad Base de Crucero | 280 px/s | Equilibrada para esquiva fluida sin sensación de inercia excesiva |
| Velocidad Reducida (Hold) | 140 px/s al mantener botón de velocidad baja | Modo de precisión para navegación en bullet hell denso |
| Input Lag Máximo Tolerado | 2 fotogramas (33 ms a 60 FPS) | Respuesta perceptualmente instantánea |
| Micro-Hitbox | Cuadrado de 4×4 píxeles — cristal central de la cabina | Las alas y propulsores son intangibles |
| Dash Invulnerable (Desbloqueado) | Duración: 0.15 s · Cooldown: 2.8 s · Invulnerabilidad: completa | Acceso a I-Frames controlado para esquivas estratégicas |
| Input Buffer para Dash | 4 fotogramas (≈ 66 ms) | Acepta input anticipado para esquivas reactivas precisas |

## **4.2. Armamento Principal — Cañón Vulcan**

* Disparo automático al mantener el botón de fuego; sin gestión de munición.

* Cadencia base: 12 proyectiles/segundo con actualización de daño proporcional a las mejoras del Taller.

* Patrón de disparo modificado por el estado del Módulo Force: frontal → arcos de propagación; trasero → supresión de flancos.

* Los proyectiles aliados tienen colisión exclusiva contra enemigos y terreno; nunca interfieren con otros proyectiles aliados.

## **4.3. Armamento Secundario — Wave Cannon**

El Wave Cannon es el arma de alto impacto cuya gestión separa a los jugadores novatos de los avanzados. Requiere acumulación de carga activa y existe una penalización implícita por liberación prematura.

| Fase de Carga | Duración | Efecto | Utility |
| ----- | ----- | ----- | ----- |
| Sin carga | — | Sin disparo secundario | — |
| Carga Parcial (1 bucle) | 0.5 s | Láser penetrante corto — atraviesa 2 enemigos en línea | Anti-columna |
| Carga Media (2 bucles) | 1.0 s | Láser penetrante largo — atraviesa pantalla completa | Anti-formación lineal |
| Carga Completa (3 bucles) | 1.5 s | Onda expansiva espiral — destruye proyectiles enemigos de clase menor en radio amplio | Limpieza de pantalla \+ daño masivo |

| ◆  Utilidad Dual del Wave Cannon La carga completa no solo inflige el máximo daño: también anula o incinera enjambres de balas enemigas de clase menor, limpiando pasillos seguros a través de formaciones densas. Esta propiedad dual convierte al Wave Cannon en una herramienta táctica de gestión del espacio, no solo de daño puro. |
| :---- |

## **4.4. El Módulo Cinético Force**

El Módulo Force es el pilar táctico que eleva la profundidad del combate por encima de cualquier otro shmup del género. Es una entidad orbe rodeada por un caparazón de garras mecánicas indestructible que actúa simultáneamente como escudo, amplificador de ataque y herramienta de control del espacio.

| Estado del Force | Descripción Funcional | Ventaja Táctica | Desventaja |
| ----- | ----- | ----- | ----- |
| Acoplamiento Frontal | Adherido al morro de la nave; bloquea balas frontales; convierte el Vulcan en arcos de propagación masivos | Defensa frontal total \+ DPS en área amplia | Sin cobertura trasera; vulnerable a flanqueos |
| Acoplamiento Trasero | Instalado en propulsores posteriores; emite ráfagas para suprimir flancos ciegos y emboscadas del avance del nivel | Defensa de retaguardia; esencial en zonas densas de terreno | Sin amplificación de disparo frontal |
| Despliegue Autónomo | Lanzado balísticamente hacia adelante; rebota en paredes y geometría del nivel; dispara radialmente de forma autónoma | Aniquilación de generadores fuera del área visual; control de pasillos | Jugador expuesto sin escudo físico; consume energía en Protocolo Nivel 4 |

**Sinergia Cinética:** En Despliegue Autónomo, el Módulo Force genera energía estática pasiva proporcional a la cantidad de rebotes ejecutados. Esta energía puede canalizarse para recargar instantáneamente el Wave Cannon, incentivando el pensamiento geométrico avanzado: el jugador que domine la física de los rebotes nunca esperará por la recarga del Wave Cannon.

# **5\. Progresión Roguelite, Economía y Sistemas de Ascensión**

El equilibrio de la economía dicta la longevidad del juego. A diferencia de los castigos definitivos del género arcade tradicional, el jugador retiene recursos persistentes (Chatarra de Asimilación) sin importar el resultado de la expedición, alimentando el Game Loop a través de dos canales distintos y complementarios.

## **5.1. El Taller de Modificaciones — Mejoras Horizontales**

En el menú principal inter-misiones, la Chatarra permite adquirir modificaciones que alteran fundamentalmente el estilo de combate. La restricción de diseño crítica: minimizar mejoras porcentuales pasivas e invisibles, priorizar atributos que generen nuevas posibilidades tácticas o sinergias combinadas visibles y satisfactorias.

| Modificación | Costo Base | Efecto Mecánico | Sinergia Principal |
| ----- | ----- | ----- | ----- |
| Micro-Salto Cuántico (Dash) | 450 Chatarra | Sustituye velocidad base por dash invulnerable direccional con cooldown severo (2.8 s). Estilo reactivo de alto riesgo. | Escudo de Singularidad \+ Wave Cannon (ventana de I-Frame antes de carga) |
| Escudo de Singularidad (I-Frames) | 380 Chatarra | Al recibir impacto letal, entra en fase de intangibilidad parpadeante durante 1 segundo. Una activación por run. | Dash \+ Force Autónomo (red de seguridad en momentos de pantalla saturada) |
| Sinergia Cinética | 520 Chatarra | Force en Despliegue Autónomo genera energía estática por rebotes que recarga el Wave Cannon instantáneamente. | Force Autónomo \+ Wave Cannon (loop ofensivo continuo sin espera) |
| Cápsula de Carga Dual | 290 Chatarra | El Wave Cannon alcanza la carga completa un 25% más rápido; sin penalización de daño en cargas parciales. | Sinergia Cinética (ciclo ofensivo más ágil y fluido) |
| Blindaje de Garras | 340 Chatarra | El Force en cualquier modo acoplado absorbe hasta 3 impactos antes de desacoplarse temporalmente. | Acoplamiento Frontal (posicionamiento agresivo sin penalización inmediata) |
| Sensor de Flanqueo | 260 Chatarra | Alerta visual (destello en HUD) cuando un enemigo fuera de pantalla prepara un ataque de francotirador. | Acoplamiento Trasero (información táctica \+ supresión activa) |

## **5.2. El Sistema de Protocolos Omega — Ascensión**

Resolver el juego por primera vez no representa la finalización de la experiencia. El Sistema de Protocolos Omega implementa una escalada de dificultad gradual y paramétrica que modifica el comportamiento del sistema de juego, no solo las estadísticas de los enemigos. El objetivo es que cada nivel de protocolo exija habilidades específicas, no solo mayor tolerancia al daño.

| Protocolo | Modificación Mecánica | Habilidad Requerida | Objetivo de Diseño |
| ----- | ----- | ----- | ----- |
| Nivel 0 — Iniciación | Configuración base del juego. Sin modificadores activos. | Comprensión de mecánicas fundamentales | Curva de entrada accesible para nuevos jugadores |
| Nivel 1 — Calor Bajo | Proyectiles de Represalia: 25% de probabilidad de bala rápida dirigida al destruir Zánganos base. | Gestión de la estela balística post-destrucción | Desalienta el avance temerario; introduce lectura de patrones secundarios |
| Nivel 2 — Calor Medio | Aceleración de Deriva: velocidad global de patrones \+15%; avance de cámara acelerado. | Memoria muscular y decisiones de esquiva en ventanas reducidas | Eleva el piso de habilidad requerido; presiona el uso estratégico del Wave Cannon |
| Nivel 3 — Calor Alto | Sobrecarga de Dreadnought: fase final crítica con patrones ultra-densos al 10% HP de jefes. | Maestría en rebotes del Force \+ técnica de grazing bajo presión máxima | Convierte victorias cómodas en enfrentamientos de pánico; requiere dominio completo del kit |
| Nivel 4 — Calor Máximo | Deterioro Forzado: Force en Despliegue Autónomo consume barra de energía; agotada, retorna a modo reposo. | Gestión activa del recurso de energía; estilo agresivo e integrado | Desmantela la estrategia pasiva de torreta automática; exige orchestración continua de todos los sistemas |

# **6\. Ecología de Entornos y Entidades Enemigas**

Para asegurar la viabilidad de la repetición sin comprometer el meticuloso equilibrio de las oleadas, se descarta la generación aleatoria completa. Los niveles utilizan generación procedimental ensamblada: bloques ('Chunks') diseñados a mano que el LevelManager conecta aleatoriamente dentro de restricciones de bioma y curva de dificultad progresiva.

## **6.1. Arquitectura de los Chunks de Nivel**

| Tipo de Chunk | Contenido Típico | Función en el Level Design |
| ----- | ----- | ----- |
| Chunk de Respiración | Enemigos fodder esporádicos, terreno abierto, recolectables de Chatarra | Alivio de tensión; preparación táctica y reposicionamiento del jugador |
| Chunk de Presión | Formaciones de Zánganos serpenteantes \+ Torretas de Asimilación | Condiciona el movimiento hacia zonas de fuego cruzado preparadas |
| Chunk de Franquiciado | Generadores de spawn continuos protegidos por geometría de terreno | Enseña el uso ofensivo del Force Autónomo para eliminar fuentes fuera de pantalla |
| Chunk de Encuentro Elite | Unidades de élite con patrones únicos no repetidos en chunks estándar | Picos de dificultad controlados; prepara para las mecánicas del Dreadnought siguiente |
| Chunk de Transición de Bioma | Cambio de paleta visual \+ introducción de nuevas mecánicas de terreno | Señalización clara del cambio de área; reintroduce la curiosidad del jugador |

## **6.2. Bestiario de la Alianza Biomecánica**

### **Zánganos — Clase Fodder**

* Comportamiento: formaciones serpenteantes superpuestas diseñadas para condicionar el movimiento del jugador hacia zonas de fuego cruzado específicas.

* Puntos de Salud: 1 impacto (instantáneamente letales ante cualquier daño).

* Ataque: disparo estándar de baja velocidad. En Protocolo Nivel 1: bala de represalia de alta velocidad al morir (25% probabilidad).

* Valor de Chatarra: bajo; abundantes en número.

* Función de diseño: recursos económicos sacrificables y condicionadores de movimiento pasivos.

### **Torretas de Asimilación — Clase Estática**

* Comportamiento: adheridas a techos y suelos de los chunks; emiten abanicos anchos de balas periódicamente.

* Puntos de Salud: 3-6 impactos dependiendo del bioma.

* Ataque: abanicos de 5-9 proyectiles con ángulo de cobertura de 120°; frecuencia variable según el nivel de Calor.

* Función de diseño: interrumpen los puntos de convergencia seguros identificados por el jugador; enseñan el valor del Wave Cannon para limpiar posiciones defensivas.

### **Dreadnoughts — Clase Jefe de Sector**

Los Dreadnoughts son los antagonistas principales de cada sector. Su diseño arquitectónico se basa en el concepto de Puntos Débiles Múltiples con Fases Dinámicas: la destrucción de cada componente exterior modifica los patrones de ataque del núcleo, creando un combate que evoluciona continuamente.

| Fase del Dreadnought | Estado de Componentes | Comportamiento de Ataque |
| ----- | ----- | ----- |
| Fase 1 — Armazón Completo | Baterías láser perimetrales activas \+ escudo de armazón exterior intacto | Patrones de barrera densa \+ láseres de barrido periódicos; núcleo inaccesible |
| Fase 2 — Armazón Dañado | 1-2 baterías láser destruidas; escudo con brechas explotables | Patrones asimétricos adaptados a las brechas; ventanas de ataque al núcleo limitadas |
| Fase 3 — Núcleo Expuesto | Armazón exterior eliminado; núcleo directo a la vista | Patrones de ataque máxima densidad; velocidad de proyectiles aumentada |
| Fase 4 — Colapso Crítico (≤10% HP) | Solo disponible en Protocolo Nivel 3+ | Tormenta balística caótica de máxima densidad; requiere grazing y Force activo |

# **7\. Sensación Física y Retroalimentación — Juice / Game Feel**

El impacto de cada disparo, esquiva y colisión se rige por la manipulación agresiva de las matemáticas subyacentes del motor para proporcionar retroalimentación visceral e instantánea. La filosofía central: separar la física funcional de la apariencia estética.

## **7.1. Sistema de Micro-Hitbox**

La viabilidad de sortear intrincados patrones de Bullet Hell requiere que la representación física de la nave esté divorciada de su sprite gráfico. Las alas, motores y alerones son completamente intangibles; la colisión se limita al cristal central de la cabina de 4×4 píxeles.

La técnica de Grazing (rozar proyectiles enemigos sin ser alcanzado por la hitbox central) no solo es posible: es incentivada activamente mediante la generación de Chatarra adicional y la recarga de la barra de energía del Force, convirtiendo el riesgo controlado en una estrategia de alto nivel.

## **7.2. Impactos Lumínicos — Hit Flashes**

* Todo enemigo dañado convierte su gama de colores completa a blanco puro con sobreexposición durante exactamente 0.05 segundos.

* La restauración es instantánea (no fundido), creando un efecto estroboscópico de confirmación de impacto.

* Implementado directamente en GPU mediante shader (uniform bool hit\_flash) para cero impacto en rendimiento de CPU.

* Los jefes tienen feedback adicional: partículas de explosión direccionales en el punto de impacto con colores diferenciados por tipo de daño (estándar / Wave Cannon / Force).

## **7.3. Distorsión Espacio-Temporal — Hit Stop y Screen Shake**

| Evento | Hit Stop | Screen Shake | Notas |
| ----- | ----- | ----- | ----- |
| Impacto estándar en enemigo | Sin stop | Mínimo (0.5 px radial) | Feedback sutil; no interrumpe el flujo |
| Destrucción de batería láser de Dreadnought | 0.05 s (time\_scale 0.3) | Moderado (2 px direccional) | Confirma el progreso de fase del jefe |
| Destrucción de núcleo del Dreadnought | 0.15 s (time\_scale 0.05) | Intenso (6 px \+ Perlin noise) | Catarsis máxima; libera tensión acumulada |
| Wave Cannon carga completa | 0.08 s (time\_scale 0.15) | Fuerte radial desde nave (4 px) | Peso y significado del arma definitiva |
| Colisión letal del jugador | 0.1 s (time\_scale 0.05) | Sin shake — fade a rojo | La muerte no se 'celebra' con shake para evitar confusión |

| ◆  Aislamiento de UI del Hit Stop Los elementos de HUD (barras de vida, puntuación, alertas) operan en PROCESS\_MODE\_ALWAYS, ignorando completamente las manipulaciones del Engine.time\_scale. El jugador siempre puede leer información crítica durante un Hit Stop. |
| :---- |

# **8\. Plataformas, Rendimiento y Requisitos Técnicos**

## **8.1. Plataformas Objetivo**

| Plataforma | Prioridad | Consideraciones Específicas |
| ----- | ----- | ----- |
| PC — Windows 10/11 (64-bit) | Principal | Resoluciones 1080p a 4K; soporte ultrawide 21:9 con letterbox automático |
| PC — Linux (64-bit) | Alta | Compatibilidad nativa Godot; prioridad para la comunidad indie/Steam |
| Steam Deck | Alta | Resolución 1280×800; HUD escalado al 125%; controles de gamepad optimizados |
| macOS 12+ | Media | Backend Metal vía Godot; requiere firma de aplicación (notarización Apple) |
| Consolas (Switch / PS5 / Xbox) | Futura | Certificación de plataforma; requiere auditoría de controles y rendimiento adicional |

## **8.2. Requisitos de Rendimiento**

| Especificación | Mínimos | Recomendados |
| ----- | ----- | ----- |
| Frame Rate Objetivo | 60 FPS estables (nunca por debajo de 55 FPS) | 60 FPS bloqueados con VSync |
| Resolución Base | 1280×720 | 1920×1080 |
| GPU | NVIDIA GTX 960 / AMD RX 470 (Vulkan 1.1) | NVIDIA GTX 1060 / AMD RX 580 |
| CPU | Intel i5-6600 / AMD Ryzen 5 1600 @ 60 FPS constante | Intel i7-8700 / AMD Ryzen 5 3600 |
| RAM | 4 GB | 8 GB |
| Almacenamiento | \< 500 MB (assets comprimidos con LZ4) | SSD recomendado para tiempos de carga \< 3 s |
| Proyectiles simultáneos en pantalla | Hasta 1,200 sin caída de FPS (Object Pool) | Hasta 2,000 en patrones de jefe máximos |

# **9\. Flujo del Juego y Estructura de Pantallas**

## **9.1. Mapa de Flujo Principal**

El juego se estructura en un flujo de pantallas claro y sin fricciones innecesarias. Cada transición debe ser intencionada y no interrumpir el ritmo del jugador más de lo estrictamente necesario.

| Pantalla | Propósito | Transición Siguiente |
| ----- | ----- | ----- |
| Pantalla de Título | Identidad del juego; opción de inicio rápido | → Menú Principal (automático tras X segundos o input) |
| Menú Principal | Acceso a Taller, Opciones, Nueva Run, Continuar | → Pantalla de Selección de Protocolo o directamente al nivel |
| Selección de Protocolo Omega | El jugador elige su nivel de dificultad modificado | → Transición de Carga Asíncrona |
| Pantalla de Carga Asíncrona | Animación de UI mientras se carga el nivel en segundo plano | → Nivel activo (sin freeze ni corte de BGM) |
| Nivel en Juego | Gameplay principal; HUD activo; generación procedimental | → Encuentro con Dreadnought o → Pantalla de Resultado |
| Encuentro con Dreadnought | Combate de jefe con BGM dedicado y fases dinámicas | → Pantalla de Resultado (victoria/derrota) |
| Pantalla de Resultado de Run | Estadísticas, Chatarra recogida, desglose de puntuación | → Menú Principal (con Chatarra actualizada en Taller) |
| El Taller de Modificaciones | Compra de mejoras permanentes con Chatarra acumulada | → Menú Principal |

## **9.2. Gestión del Estado de Guardado**

* Guardado automático: tras cada run completada o fallida (al llegar a la Pantalla de Resultado).

* El progreso del Taller se guarda inmediatamente al confirmar una compra.

* Las opciones de accesibilidad y configuración se guardan por separado del perfil de progreso principal.

* Integridad del guardado verificada mediante hash SHA-256 para detección de modificaciones no autorizadas.

| ◆  Política de Pérdida de Progreso El jugador NUNCA pierde Chatarra, modificaciones del Taller compradas, o progreso de Protocolos desbloqueados, independientemente del resultado de la run. Las únicas variables efímeras son: puntuación de la run actual, multiplicadores de combo, y mejoras temporales del Force recolectadas durante el nivel. |
| :---- |

**— FIN DEL DOCUMENTO PRD v2.0 —**