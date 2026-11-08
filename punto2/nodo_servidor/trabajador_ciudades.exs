Code.require_file("ciudades.exs")

defmodule TrabajadorCiudad do

  def leer_procesar(ruta) do
    case File.read(ruta) do
      {:ok, c} ->
        String.split(c, "\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.reduce(%{tipo: :ciudad ,validacion: [], cant_rechazados: 0}, fn linea , acc ->

          case String.split(linea,"@") do

            [id_ciudad, nombre, numeros_habitantes] ->
              with {h, ""} <- Integer.parse(String.trim(numeros_habitantes)) do

                case Ciudades.validar_crear(id_ciudad, nombre, h) do
                  {:ok,c} -> Map.update!(acc, :validacion, fn l -> [c | l] end)
                  {:error, :formato_invalido} -> Map.update!(acc, :cant_rechazados, &(&1 + 1))

                end
              else
                _ -> Map.update!(acc, :cant_rechazados, &(&1 + 1))

              end

            _ -> Map.update!(acc, :cant_rechazados, &(&1 + 1))
          end
        end)
      {:error, razon} ->
        %{tipo: :ciudad, error: razon}
    end
  end

end
