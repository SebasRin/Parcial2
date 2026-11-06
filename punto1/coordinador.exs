Code.require_file("trabajador_ciudades.exs")
Code.require_file("trabajador_movimientos.exs")

defmodule Coordinador do

  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"

  def generar_reporte do
    pdi_coordinador = spawn(fn -> loop(2) end)

    spawn(fn ->
      resultado = TrabajadorCiudad.leer_procesar(@ruta_ciudades)
      send(pdi_coordinador, {:ciudad, resultado})
    end)

    Process.sleep(500)

    spawn(fn ->
      resultado = TrabajadorMovimientos.leer_procesar(@ruta_movimientos)
      send(pdi_coordinador, {:movimientos, resultado})
    end)

    Process.sleep(500)
  end

  defp loop(cantidad) do
    if cantidad > 0 do
      receive do
        {:ciudad, resultado} ->
          IO.puts("Resultado Ciudades: #{inspect(resultado)}")
          loop(cantidad - 1)
        {:movimientos, resultado} ->
          IO.puts("Resultado Movimientos: #{inspect(resultado)}")
          loop(cantidad - 1)
      end
    end
  end


end
Coordinador.generar_reporte()
