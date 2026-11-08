defmodule NodoCliente do

  @nombre_servicio_local :servicio_respuesta
  @servicio_local {@nombre_servicio_local, :nodocliente@cliente}
  @nodo_remoto :nodoservidor@localhost
  @servicio_remoto {:servicio_sismos, @nodo_remoto}

  @solicitudes [
    {:reporte_ciudad_sin_mv},{:reporte_ciudad_con_mv},{:reporte_general},:fin
  ]

  def main() do
    Util.mostrar_mensaje("PROCESO PRINCIPAL")
    @nombre_servicio_local
    |> registrar_servicio()
    establecer_conexion(@nodo_remoto)
    |> iniciar_produccion()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  defp establecer_conexion(nodo_remoto) do
    Node.connect(nodo_remoto)
  end

  defp iniciar_produccion(false),
    do: Util.mostrar_error("No se pudo conectar con el nodo servidor")

  defp iniciar_produccion(true) do
    enviar_mensajes()
    recibir_respuestas()
  end

  defp enviar_mensajes() do
    Enum.each(@solicitudes, &enviar_mensaje/1)
  end

  defp enviar_mensaje(mensaje) do
    send(@servicio_remoto, {@servicio_local, mensaje})
  end

  defp recibir_respuestas() do
    receive do
      :fin ->
        :ok
      respuesta ->
        Util.mostrar_mensaje("#{inspect(respuesta,pretty: true)}")
        recibir_respuestas()
    end
  end
end

NodoCliente.main()
