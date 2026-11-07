defmodule Persistencia do
  @ruta "resources/reporte_sismos.txt"

  def guardar_reporte(reporte_texto) do
    File.write(@ruta,reporte_texto)
  end
end
