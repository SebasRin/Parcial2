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
      |> IO.inspect()
    end
  end

  defp relacion_movimientos_ciudad(estado) do
    mapa_ciudades = Enum.find(estado, &(&1.tipo == :ciudad))
    mapa_movimientos = Enum.find(estado, &(&1.tipo == :movimiento))

    ciudades = mapa_ciudades.validacion
    |> Enum.map(&(&1.id_ciudad))
    movimientos = mapa_movimientos.validacion

    Enum.filter(movimientos,fn movimiento ->
      movimiento.id_ciudad in ciudades
    end )
  end

end
Coordinador.generar_reporte()
