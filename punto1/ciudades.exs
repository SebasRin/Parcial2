defmodule Ciudades do

  defstruct id_ciudad: "", nombre: "", numero_habitantes: 0

  def validar_crear(id_ciudad, nombre, numero_habitantes) do
    if validar_string?(id_ciudad) and validar_string?(nombre) and validar_numero_habitantes(numero_habitantes) do
      ciudad = %Ciudades{id_ciudad: id_ciudad, nombre: nombre, numero_habitantes: numero_habitantes}
      {:ok,ciudad}
    else
      {:error, :formato_invalido}
    end

  end

  defp validar_string?(string)when is_binary(string) and not(string == "") ,do: true

  defp validar_string?(_string),do: false

  defp validar_numero_habitantes(num)when is_integer(num) and num > 0, do: true

  defp validar_numero_habitantes(_num), do: false

end
