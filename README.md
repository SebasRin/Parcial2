# Parcial 2 – Observatorio Sismológico

**Universidad del Quindío · Programa de Ingeniería de Sistemas y Computación · Programación 3**

Aplicación en Elixir que lee una copia local de datos sísmicos (ciudades y movimientos), valida los registros y genera un reporte de sismos por ciudad.

| Punto | Descripción |
|-------|-------------|
| **Punto 1** | Reporte local: un coordinador lanza dos procesos trabajadores (uno por archivo), calcula el reporte, lo muestra en consola y lo guarda en un archivo. |
| **Punto 2** | Consulta entre nodos: un nodo servidor atiende solicitudes de reportes enviadas por un nodo cliente mediante `send` y `receive`. |

## Estructura del repositorio

```
Parcial2/
├── README.md
├── punto1/
│   ├── coordinador.exs             # Punto de entrada
│   ├── trabajador_ciudades.exs
│   ├── trabajador_movimientos.exs
│   ├── ciudades.exs                # Struct y validación de ciudades
│   ├── movimientos.exs             # Struct y validación de movimientos
│   ├── persistencia.exs            # Escritura del reporte
│   └── resources/
│       ├── ciudades.txt
│       ├── movimientos.txt
│       └── reporte_sismos.txt      # Se genera al ejecutar
└── punto2/
    ├── nodo_cliente/
    │   ├── nodo-cliente.exs
    │   ├── cookie
    │   └── Elixir.Util.beam
    ├── nodo_servidor/
    │   ├── nodo-servidor.exs
    │   ├── coordinador.exs
    │   ├── trabajador_ciudades.exs
    │   ├── trabajador_movimientos.exs
    │   ├── ciudades.exs
    │   ├── movimientos.exs
    │   ├── cookie
    │   ├── cookie.exs              
    │   └── Elixir.Util.beam
    └── resources/
        ├── ciudades.txt
        └── movimientos.txt
```

## Formato de los archivos de entrada

Sin encabezado, un registro por línea, campos separados por `@`.

**`ciudades.txt`** → `idCiudad@nombre@numeroHabitantes`

```
C01@Armenia@304314
C02@Calarcá@78684
C03@Circasia@30941
```

**`movimientos.txt`** → `código@idCiudad@horaInicio@horaFinal@magnitud@profundidad`

```
S001@C01@08:15:02@08:15:18@3.4@18.0
S002@C02@09:30:10@09:30:29@4.1@25.0
S003@C01@11:42:00@11:42:12@2.8@10.0
```

Con estos datos de prueba, **C01** (Armenia) y **C02** (Calarcá) tienen movimientos y **C03** (Circasia) no tiene ninguno.

### Validación

Una línea se rechaza (y se cuenta como registro rechazado) si tiene un formato incorrecto, un campo obligatorio vacío o un dato 
inválido (habitantes no entero o ≤ 0, magnitud no decimal, profundidad < 0, hora inválida). Las líneas vacías se ignoran. 
También se rechaza todo movimiento cuyo `idCiudad` no exista en el catálogo de ciudades.

---

## Punto 1 – Reporte local

- **Archivos de entrada:** `punto1/resources/ciudades.txt` y `punto1/resources/movimientos.txt`
- **Reporte generado:** `punto1/resources/reporte_sismos.txt` (cada ejecución exitosa reemplaza el contenido anterior)

**Comando** (ejecutar desde la carpeta `punto1/`, porque las rutas a `resources/` son relativas):

```bash
cd punto1
elixir coordinador.exs
```

El reporte se muestra en consola y se guarda en el archivo indicado. Para cada ciudad incluye nombre y habitantes, 
el listado de movimientos, el total, el movimiento de mayor magnitud y la profundidad promedio (2 decimales), 
además del total de registros rechazados por archivo.

---

## Punto 2 – Consulta de reportes entre nodos

Se usan **dos terminales**. Primero se inicia el servidor y luego el cliente.

| Nodo | Nombre | Proceso registrado |
|------|--------|--------------------|
| Servidor | `nodoservidor@localhost` | `:servicio_sismos` |
| Cliente | `nodocliente@cliente` | `:servicio_respuesta` |

### Cookie

Ambos nodos deben usar **la misma cookie**. El repositorio incluye un archivo `cookie` idéntico en `nodo_servidor/` y `nodo_cliente/`.
Para generar una cookie nueva, ejecuta en punto2/nodo_servidor/:

```bash
elixir cookie.exs
```

y copia el resultado en el archivo cookie de ambas carpetas.

### Paso 1 – Terminal 1: servidor

```bash
cd punto2/nodo_servidor
elixir --sname nodoservidor@localhost --cookie cookie nodo-servidor.exs
```

Debe mostrar `[Servidor] Iniciado`. Déjalo en ejecución.

### Paso 2 – Terminal 2: cliente

```bash
cd punto2/nodo_cliente
elixir --sname nodocliente@cliente --cookie cookie nodo-cliente.exs
```

> Cada comando debe ejecutarse desde la carpeta indicada.

### Solicitudes que atiende el servidor

| Solicitud | Respuesta |
|-----------|-----------|
| `{:reporte_ciudad_con_mv}`| Reporte de la cuidad con movimientos asociados.|
| `{:reporte_ciudad_sin_mv}`| Reporte de la cuidad sin movimientos asociados.|
| `{:reporte_ciudad, idCiudad}` | Reporte de la ciudad: nombre, habitantes, movimientos, total, mayor magnitud y profundidad promedio. Si no existe: «La ciudad no está registrada». |
| `:reporte_general` | Reporte de todas las ciudades válidas y conteo de rechazados por archivo. |
| `:fin` | Confirmación `:fin`, enviada después de todas las respuestas anteriores. |

Cada mensaje tiene la forma `{destino_respuesta, solicitud}`.

## Verificación del punto 2

El cliente envía, en este orden, las siguientes solicitudes y luego :fin:

| # | Solicitud | Identificador | Caso |
|---|-----------|---------------|------|
| 1 | `{:reporte_ciudad, "C01"}` | `C01` (Armenia) | Ciudad **con** movimientos |
| 2 | `{:reporte_ciudad, "C03"}` | `C03` (Circasia) | Ciudad **sin** movimientos |
| 3 | `{:reporte_ciudad, "C99"}` | `C99` | Ciudad **inexistente** |
| 4 | `:reporte_general` | — | Reporte general |

**Ejecutar el cliente por segunda vez:** con el servidor todavía corriendo en la Terminal 1, vuelve a ejecutar en la Terminal 2 el mismo comando del cliente:

```bash
cd punto2/nodo_cliente
elixir --sname nodocliente@cliente --cookie cookie nodo-cliente.exs
```

Debe mostrar de nuevo las cuatro respuestas en el mismo orden y terminar al recibir `:fin`. El servidor sigue atendiendo solicitudes.

---

## Reflexión sobre el uso de inteligencia artificial

### 1. Herramientas y agentes

- **ChatGPT:** lo utilicé como herramienta de depuración. Me ayudó a entender y solucionar errores específicos de sintaxis y ejecución en Elixir, como el `ArgumentError` en la conversión de strings, causado por los saltos de línea `\r\n` en los archivos de entrada.
- **Documentación oficial de Elixir:** la usé para consultar funciones, por ejemplo [`Time.new/5`](https://elixir.hexdocs.pm/1.20.5/Time.html#new/5-examples).

### 2. Caso decisivo

Cuando intenté ejecutar el cliente por segunda vez para la prueba de las "dos ejecuciones consecutivas", el servidor ya no respondía.

La IA me explicó que el mensaje `:fin` estaba terminando el proceso `loop`, aunque el nodo seguía vivo gracias a `Process.sleep(:infinity)`. El cliente intentaba enviar mensajes a un nombre de proceso (`:servicio_sismos`) que ya no existía en el servidor.

La solución propuesta fue usar un `case` dentro del `receive` del servidor. En lugar de dejar que el proceso muera, la rama de `:fin` imprime un mensaje de confirmación y vuelve a llamar a `loop(reporte)`.

Adapté esta lógica y la probé: al ejecutar el cliente por segunda vez, comprobé que el servidor mantenía el servicio registrado y respondía correctamente las 4 solicitudes de nuevo.

### 3. Idea diferente de la clase

En clase vimos el manejo básico de excepciones, pero la IA me sugirió aplicar un concepto de **tolerancia a fallos en la concurrencia**: envolver los procesos hijos en bloques `try/rescue`.

Normalmente, si un proceso creado con `spawn` falla, muere silenciosamente y el proceso padre se queda esperando su respuesta para siempre. La sugerencia fue que cada `spawn` atrapara sus propios errores y enviara al coordinador un mensaje con el error, por ejemplo `%{error: ...}`.

Lo implementé y lo probé borrando el archivo `ciudades.txt`: el sistema no colapsó, el coordinador recibió el mensaje de error y el servidor siguió vivo y funcional.

### 4. Conclusiones

**Lo que comprendo por mi cuenta:** el paso de mensajes con `send` y `receive`, cómo levantar y conectar los nodos, el uso de `spawn` para crear procesos y cómo el *pattern matching* facilita la extracción de datos.

**Qué cambiaría en un siguiente proyecto:** en lugar de usar `spawn` y `receive` manual para las tareas concurrentes, implementaría `Task.async` y `Task.await`:

- `Task.async` crea un proceso ligado y monitoreado automáticamente por el proceso que lo inició.
- `Task.await` recibe el resultado de forma síncrona, lo que elimina el `loop` manual con `receive` y el contador.
- `Task.await` propaga los fallos de la tarea al proceso principal, lo que simplificaría mi lógica actual de `try/rescue` dentro de cada `spawn`. Si un archivo falla al leerse, el error se podría manejar de forma centralizada, en lugar de enviar mapas `%{error: ...}` entre procesos.
Esto hara que el codigo sea mas legible y menos propenso a errores.
