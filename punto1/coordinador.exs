Code.require_file("trabajador_ciudades.exs")
Code.require_file("trabajador_movimientos.exs")
Code.require_file("persistencia.exs")

defmodule Coordinador do

  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"

  def generar_reporte do
    pid_coordinador = spawn(fn -> loop(2,[]) end)

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
        e -> %{tipo: :movimientos, error: Exception.message(e)}
      end
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
      ciudad = Enum.find(estado,fn x -> is_map(x) and x.tipo == :ciudad end)
      movimiento = Enum.find(estado,fn x -> is_map(x) and x.tipo == :movimiento end)
      if is_map(ciudad) and is_map(movimiento)  do
        datos = relacion_movimientos_ciudad(estado)
        reporte = reporte_ciudad(datos)
        texto = mostrar_reporte(reporte, datos)

          case Persistencia.guardar_reporte(texto) do
            :ok -> IO.puts("\nReporte guardado exitosamente")
            {:error,razon} -> IO.puts("\nError al guardar el reporte: #{inspect(razon)}")
          end

        else
          IO.puts("Error: No se pudo generar el reporte porque fallo la lectura de un archivo")
          Enum.each(estado, fn e ->
            case e do
              {:error, razon} -> IO.puts("Un archivo fallo: #{inspect(razon)}")
              _ -> :ok
            end
          end)
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
    ciudades = Enum.map(reporte,fn r ->
      movimientos =
      if r.movimientos_asociados == :Sin_movimientos_registrados do
        "  - Sin movimientos registrados"
      else
        Enum.map(r.movimientos_asociados, fn m ->
          "  * #{m.codigo} | Inicio: #{m.hora_inicio} | Fin: #{m.hora_final} | Mag: #{m.magnitud} | Prof: #{m.profundidad}"
        end) |> Enum.join("\n")
      end

      """
      Ciudad: #{r.nombre} (Habitantes: #{r.numero_habitantes})
      #{movimientos}
        Total movimientos: #{r.cant_movimientos_registrados}
        Mayor magnitud: #{inspect(r.mayor_magnitud)}
        Profucndiadd promedio: #{r.promedio_profundidad}
      """
    end) |> Enum.join("\n")

    rechazados = """
    === REGISTROS RECHAZADOS ===
    Ciudades rechazadas: #{datos.rechazados_ciudades}
    Movimientos rechazados: #{datos.rechazados_movimientos}
    """

    texto_final = "=== Reporte por ciudad ===\n\n" <> ciudades <> "\n" <> rechazados

    IO.puts(texto_final)

    texto_final
  end

end
Coordinador.generar_reporte()
