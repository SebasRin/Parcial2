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
      datos = relacion_movimientos_ciudad(estado)
      reporte = reporte_ciudad(datos)
      mostrar_reporte(reporte, datos)
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
          [] -> %{nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes,movimientos_asociados: :Sin_movimientos_registrados,
          cant_movimientos_registrados: 0,mayor_magnitud: :No_aplica ,promedio_profundidad: :No_aplica}
          _ -> movimiento_mayor = Enum.max_by(movimientos_asociados,&(&1.magnitud))
              profundidades = Enum.map(movimientos_asociados,fn m -> m.profundidad end)
              promedio_profundidad = Float.round(Enum.sum(profundidades) / length(movimientos_asociados),2)
              %{nombre: ciudad.nombre,numero_habitantes: ciudad.numero_habitantes,movimientos_asociados: movimientos_asociados, cant_movimientos_registrados: length(movimientos_asociados),mayor_magnitud: {movimiento_mayor.codigo,movimiento_mayor.magnitud},promedio_profundidad: promedio_profundidad}

        end
    end)
  end

  defp mostrar_reporte(reporte,datos) do
    IO.puts("\n=== REPORTE POR CIUDAD ===")
    reporte
    |> Enum.each(fn r ->
      IO.puts("\nCiudad: #{r.nombre} (Habitantes: #{r.numero_habitantes})")

      if r.movimientos_asociados == :Sin_movimientos_registrados do
        IO.puts("  - Sin movimientos registrados")
      else
        Enum.each(r.movimientos_asociados, fn m ->
          IO.puts("  * #{m.codigo} | Inicio: #{m.hora_inicio} | Fin: #{m.hora_final} | Mag: #{m.magnitud} | Prof: #{m.profundidad}")
        end)
      end

      IO.puts("  Total movimientos: #{r.cant_movimientos_registrados}")
      IO.puts("  Mayor magnitud: #{inspect(r.mayor_magnitud)}")
      IO.puts("  Profundidad promedio: #{r.promedio_profundidad}")
    end)

    # 3. Mostramos el total de rechazados
    IO.puts("\n=== REGISTROS RECHAZADOS ===")
    IO.puts("Ciudades rechazadas: #{datos.rechazados_ciudades}")
    IO.puts("Movimientos rechazados: #{datos.rechazados_movimientos}")

  end

end
Coordinador.generar_reporte()
