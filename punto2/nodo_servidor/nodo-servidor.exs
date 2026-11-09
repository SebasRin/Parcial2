Code.require_file("coordinador.exs")

defmodule NodoServidor do
  @nombre_servicio_local :servicio_sismos

  def main() do
    d = Coordinador.generar_reporte()
    reporte = d.ciudades
    rechazados = d.rechazados
    pid = spawn(fn -> loop(reporte,rechazados) end)
    Util.mostrar_mensaje("[Servidor] Iniciado")
    registrar_servicio(pid,@nombre_servicio_local)
    Process.sleep(:infinity)

  end

  defp registrar_servicio(pid,nombre_servicio_local),
    do: Process.register(pid, nombre_servicio_local)

  defp loop(reporte, rechazados) do
    receive do
      {destino, solicitud} ->
        Util.mostrar_mensaje("[servidor] recibio #{inspect(solicitud)} de #{inspect(destino)}")
        respuesta =
          try do
            procesar_solicitud(reporte,rechazados,solicitud)
          rescue
            e -> {:error, Exception.message(e)}
          end

        send(destino, {solicitud,respuesta})

        case respuesta do
          :fin ->
            Util.mostrar_mensaje("[servidor] recibio :fin, cliente termino \n")
          _ -> Util.mostrar_mensaje("[servidor] respondio a #{inspect(solicitud)}")
        end

        loop(reporte,rechazados)

    end
  end

  defp procesar_solicitud(_reporte,_rechazados,:fin), do: :fin
  defp procesar_solicitud(reporte,_rechazados,{:reporte_ciudad_con_mv})do
    case Enum.filter(reporte, fn r -> r.movimientos_asociados != :Sin_movimientos_registrados end) do
      [] -> :No_hay_ciudades_con_movimientos
      mapa -> mapa
    end
  end
  defp procesar_solicitud(reporte,_rechazados,{:reporte_ciudad_sin_mv}) do
    case Enum.filter(reporte, fn r -> r.movimientos_asociados == :Sin_movimientos_registrados end) do
      [] -> :No_hay_ciudades_sin_movimientos
      mapa -> mapa
    end
  end
  defp procesar_solicitud(reporte,_rechazados,{:reporte_ciudad, id_ciudad})do
    case Enum.find(reporte, &(&1.id_ciudad == id_ciudad)) do
      nil -> :Ciudad_no_existe
      ciudad -> ciudad
    end
  end
  defp procesar_solicitud(reporte,rechazados,{:reporte_general})do
    case reporte do
      [] -> :No_hay_ciudades_registradas
      reporte -> {reporte, rechazados}
    end
  end

end

NodoServidor.main()
