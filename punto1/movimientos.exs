defmodule Movimientos do

  defstruct codigo: "", id_ciudad: "", hora_inicio: "00:00:00", hora_final: "00:00:00", magnitud: 0.0, profundidad: 0


  def validar_crear(codigo, id_ciudad, hora_inicio,hora_final,magnitud,profundidad) do
    if validar_string?(codigo) and validar_string?(id_ciudad) and validar_hora?(hora_inicio) and validar_hora?(hora_final) and is_float(magnitud) and profundidad >= 0 do
      movimiento = %Movimientos{codigo: codigo, id_ciudad: id_ciudad, hora_inicio: hora_inicio, hora_final: hora_final, magnitud: magnitud, profundidad: profundidad}
      {:ok,movimiento}
    else
      {:error, :formato_invalido}
    end
  end

  defp validar_string?(string)when is_binary(string) and not(string == "") ,do: true

  defp validar_string?(_string),do: false

  defp validar_hora?(hora) do
    case Time.from_iso8601(hora) do
      {:ok,_} -> true
      {:error,_} -> false
    end
  end
end
