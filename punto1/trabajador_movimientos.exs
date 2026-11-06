defmodule TrabajadorMovimientos do

  def leer_procesar(ruta) do
    case File.read(ruta) do
      {:ok, c} ->
        String.split(c, "\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(fn linea ->
          [codigo,id_ciudad,hora_inicio,hora_final,magnitud,profundidad] = String.split(linea,"@")
          %{codigo: codigo, id_ciudad: id_ciudad, hora_inicio: hora_inicio, hora_final: hora_final, magnitud: magnitud, profundidad: profundidad}
        end)
      {:error, razon} ->
        {:error, razon}
    end
  end

end
