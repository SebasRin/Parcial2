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
