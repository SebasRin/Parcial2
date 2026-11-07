Code.require_file("movimientos.exs")

defmodule TrabajadorMovimientos do

  def leer_procesar(ruta) do
    case File.read(ruta) do
      {:ok, c} ->
        String.split(c, "\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.reduce(%{tipo: :movimiento,validacion: [], cant_rechazados: 0}, fn linea , acc ->

          case String.split(linea,"@") do

            [codigo,id_ciudad,hora_inicio,hora_final,magnitud,profundidad] ->
              with {m, ""} <- Float.parse(magnitud),
              {p, ""} <- Float.parse(profundidad) do

                case Movimientos.validar_crear(codigo,id_ciudad,hora_inicio,hora_final,m,p) do
                  {:ok,m} -> Map.update!(acc, :validacion, fn l -> [m | l] end)
                  {:error, :formato_invalido} -> Map.update!(acc, :cant_rechazados, &(&1 + 1))
                end
              else
                _ -> Map.update!(acc, :cant_rechazados, &(&1 + 1))
              end

            _ -> Map.update!(acc, :cant_rechazados, &(&1 + 1))
          end
        end)
      {:error, razon} ->
        {:error, razon}
    end
  end

end
