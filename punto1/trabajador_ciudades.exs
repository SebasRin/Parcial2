defmodule TrabajadorCiudad do

  def leer_procesar(ruta) do
    case File.read(ruta) do
      {:ok, c} ->
        String.split(c, "\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(fn linea ->
          [id_cuidad, nombre, numeros_habitantes] = String.split(linea,"@")
          %{id_ciudad: id_cuidad, nombre: nombre, numero_habitantes: String.to_integer(numeros_habitantes)}
        end)
      {:error, razon} ->
        {:error, razon}
    end
  end

end
