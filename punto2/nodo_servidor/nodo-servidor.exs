Code.require_file("coordinador.exs")

defmodule NodoServidor do
  @nombre_servicio_local :servicio_sismos

  def main() do
    Util.mostrar_mensaje("PROCESO SECUNDARIO")
    registrar_servicio(@nombre_servicio_local)
    procesar_solicitud()

  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  defp procesar_solicitud() do
    receive do
      {destino, solicitud} ->
        reporte = Coordinador.generar_reporte()
        respuesta = procesar_solicitud(reporte,solicitud)
        send(destino, respuesta)
        if respuesta != :fin, do: procesar_solicitud()
    end
  end

  defp procesar_solicitud(_reporte,:fin), do: :fin
  defp procesar_solicitud(reporte,{:reporte_ciudad_con_mv}),do: Enum.filter(reporte, fn r -> r.movimientos_asociados != :Sin_movimientos_registrados end)
  defp procesar_solicitud(reporte,{:reporte_ciudad_sin_mv}),do: Enum.filter(reporte, fn r -> r.movimientos_asociados == :Sin_movimientos_registrados end)
  defp procesar_solicitud(reporte,{:reporte_ciudad, id_ciudad}),do: Enum.find(reporte, &(&1.id_ciudad == id_ciudad))
  defp procesar_solicitud(reporte,{:reporte_general}),do: reporte

end

NodoServidor.main()
