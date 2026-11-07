Code.require_file("trabajador_ciudades.exs")
Code.require_file("trabajador_movimientos.exs")

defmodule Coordinador do

  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"

  def generar_reporte do
    pid_coordinador = spawn(fn -> loop(2,[]) end)

    spawn(fn ->
      resultado = TrabajadorCiudad.leer_procesar(@ruta_ciudades)
      send(pid_coordinador, {:ciudad, resultado})
    end)
    Process.sleep(500)

    spawn(fn ->
      resultado = TrabajadorMovimientos.leer_procesar(@ruta_movimientos)
      send(pid_coordinador, {:movimientos, resultado})
    end)
    Process.sleep(500)
  end

  defp loop(cantidad,estado) do
    if cantidad > 0 do
      receive do
        {:ciudad, resultado} ->
          loop(cantidad - 1, estado ++ [resultado])
        {:movimientos, resultado} ->
          loop(cantidad - 1, estado ++ [resultado])
      end
    else
      relacion_movimientos_ciudad(estado)
      |> reporte_ciudad()
      |> IO.inspect()
    end
  end

  defp relacion_movimientos_ciudad(estado) do
    mapa_ciudades = Enum.find(estado, &(&1.tipo == :ciudad))
    mapa_movimientos = Enum.find(estado, &(&1.tipo == :movimiento))

    ciudades = mapa_ciudades.validacion
    |> Enum.map(&(&1.id_ciudad))
    movimientos = mapa_movimientos.validacion

    movimientos_filtrados =
    Enum.filter(movimientos,fn movimiento ->
      movimiento.id_ciudad in ciudades
    end)
    %{ciudades: mapa_ciudades.validacion, movimientos: movimientos_filtrados}
  end

  defp reporte_ciudad(datos) do
    movimientos = datos.movimientos
    ciudades = datos.ciudades

    Enum.map(ciudades, fn ciudad ->

      movimientos_asociados =
        Enum.filter(movimientos, fn movimiento ->
          movimiento.id_ciudad == ciudad.id_ciudad
        end)

        case movimientos_asociados do
          [] -> %{nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes,movimientos_asociados: :Sin_movimientos_registrados,
          cant_movimientos_registrados: 0,mayor_magnitud: :No_aplica ,promedio_profundidad: :No_aplica}
          _ -> movimiento_mayor = Enum.max_by(movimientos_asociados,&(&1.magnitud))
              profundidades = Enum.map(movimientos_asociados,fn m -> m.profundidad end)
              promedio_profundidad = Enum.sum(profundidades) / length(movimientos_asociados)
              %{nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes,movimientos_asociados: movimientos_asociados, cant_movimientos_registrados: length(movimientos_asociados),mayor_magnitud: {movimiento_mayor.codigo,movimiento_mayor.magnitud},promedio_profundidad: promedio_profundidad}

        end
    end)
  end

  defp 

end
Coordinador.generar_reporte()
