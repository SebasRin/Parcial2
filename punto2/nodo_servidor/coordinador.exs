Code.require_file("trabajador_ciudades.exs")
Code.require_file("trabajador_movimientos.exs")
#Code.require_file("persistencia.exs")

defmodule Coordinador do

  @ruta_ciudades "../resources/ciudades.txt"
  @ruta_movimientos "../resources/movimientos.txt"

  def generar_reporte do
    pid_padre = self()
    pid_coordinador = spawn(fn -> loop(2,[],pid_padre) end)

    spawn(fn ->
      resultado =
        try do
          TrabajadorCiudad.leer_procesar(@ruta_ciudades)
        rescue
          e -> %{tipo: :ciudad, error: Exception.message(e)}
        end
      send(pid_coordinador, {:ciudad, resultado})
    end)
    Process.sleep(500)

    spawn(fn ->
      resultado =
        try do
          TrabajadorMovimientos.leer_procesar(@ruta_movimientos)
        rescue
          e -> %{tipo: :ciudad,error: Exception.message(e)}
        end
      send(pid_coordinador, {:movimientos, resultado})
    end)
    Process.sleep(500)

    receive do
      {:reporte_ok, reporte} -> reporte
      {:error_archivo, tipo, razon} -> {:error, tipo,razon}
    after
      10000 -> {:error, :timeout, "El coodinador no respondio"}
    end

  end

  defp loop(cantidad,estado,pid_padre) do
    if cantidad > 0 do
      receive do
        {:ciudad, resultado} ->
          loop(cantidad - 1, estado ++ [resultado],pid_padre)
        {:movimientos, resultado} ->
          loop(cantidad - 1, estado ++ [resultado],pid_padre)
      end
    else
      ciudad = Enum.find(estado,fn x -> is_map(x) and x.tipo == :ciudad end)
      movimiento = Enum.find(estado,fn x -> is_map(x) and x.tipo == :movimiento end)

      cond do
        ciudad == nil or Map.get(ciudad,:error) != nil ->
        send(pid_padre,{:error_archivo, :ciudad, Map.get(ciudad,:error, "Error desconocido") })

        movimiento == nil or Map.get(movimiento,:error) != nil ->
        send(pid_padre,{:error_archivo, :movimiento, Map.get(movimiento,:error, "Error desconocido") })

        true ->
          datos = relacion_movimientos_ciudad(estado)
          reporte = reporte_ciudad(datos)

          send(pid_padre, {:reporte_ok, reporte})
      end
    end
  end


  defp relacion_movimientos_ciudad(estado) do
    mapa_ciudades = Enum.find(estado, &(&1.tipo == :ciudad))
    mapa_movimientos = Enum.find(estado, &(&1.tipo == :movimiento))

    ciudades = mapa_ciudades.validacion
    |> Enum.map(&(&1.id_ciudad))


    movimientos = Enum.reverse(mapa_movimientos.validacion)

    {movimientos_validos, movimientos_invalidos}=
    Enum.split_with(movimientos,fn movimiento ->
      movimiento.id_ciudad in ciudades
    end)

    total_rechazados_movimi = mapa_movimientos.cant_rechazados + length(movimientos_invalidos)

    %{ciudades: mapa_ciudades.validacion, movimientos: movimientos_validos, rechazados_ciudades: mapa_ciudades.cant_rechazados, rechazados_movimientos: total_rechazados_movimi}
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
          [] -> %{id_ciudad: ciudad.id_ciudad,nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes,
          cant_movimientos_registrados: 0,mayor_magnitud: :No_aplica ,promedio_profundidad: :No_aplica,movimientos_asociados: :Sin_movimientos_registrados}
          _ -> movimiento_mayor = Enum.max_by(movimientos_asociados,&(&1.magnitud))
              profundidades = Enum.map(movimientos_asociados,fn m -> m.profundidad end)
              promedio_profundidad = Float.round(Enum.sum(profundidades) / length(movimientos_asociados),2)
              %{id_ciudad: ciudad.id_ciudad,nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes, cant_movimientos_registrados: length(movimientos_asociados),mayor_magnitud: {movimiento_mayor.codigo,movimiento_mayor.magnitud},promedio_profundidad: promedio_profundidad,movimientos_asociados: movimientos_asociados}
        end
    end)
  end

end
Coordinador.generar_reporte()
