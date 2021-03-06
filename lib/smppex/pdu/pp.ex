defmodule SMPPEX.Pdu.PP do

  alias SMPPEX.Pdu
  alias SMPPEX.Protocol.TlvFormat

  use Dye

  @pad ""
  @indent "  "
  @field_inspect_limit 999999

  @spec format(Pdu.t, String.t, String.t) :: iolist

  def format(pdu, indent \\ @indent, pad \\ @pad) do
    [ "\n", pdu |> pdu_lines |> Enum.map(fn([section_head | section_lines]) ->
      [ pad, section_head, "\n", section_lines |> Enum.map(fn(line) ->
        [ pad, indent, line, "\n"]
      end) ]
    end) ]
  end

  defp pdu_lines(pdu) do
    [
      header(pdu),
      mandatory_fields(pdu),
      optional_fields(pdu)
    ]
  end

  defp header(pdu) do
    [
      name(pdu),
      [ pp_field_name("command_id"), ": ", pdu |> Pdu.command_id |> inspect |> pp_val ],
      [ pp_field_name("command_status"), ": ", pdu |> Pdu.command_status |> pp_command_status ],
      [ pp_field_name("sequence_number"), ": ", pdu |> Pdu.sequence_number |> inspect |> pp_val ]
    ]
  end

  defp name(pdu) do
    ["pdu: ", pp_command_name(pdu)]
  end

  defp mandatory_fields(pdu) do
    [ [ "mandatory fields:", pdu |> Pdu.mandatory_fields |> pp_empty_list ] ] ++
      (pdu |> Pdu.mandatory_fields |> Map.to_list |> pp_fields)
  end

  defp optional_fields(pdu) do
    [ [ "optional fields:", pdu |> Pdu.optional_fields |> pp_empty_list ] ] ++
      (pdu |> Pdu.optional_fields |> Map.to_list |> name_known_tlvs |> pp_fields)
  end

  defp name_known_tlvs(_, res \\ [])
  defp name_known_tlvs([], res), do: Enum.reverse(res)
  defp name_known_tlvs([{k, v} | left], res) do
    case TlvFormat.name_by_id(k) do
      {:ok, name} -> name_known_tlvs(left, [{name, v} | res])
      :unknown -> name_known_tlvs(left, [{k, v} | res])
    end
  end

  defp pp_empty_list(map) when map == %{}, do: " []"
  defp pp_empty_list(_), do: ""

  defp pp_command_status(status) do
    case status do
      0 -> ~s/0 (ok)/DGd
      _ -> ~s/#{status} (error)/DRd
    end
  end

  defp pp_field_name(field_name) do
    ~s/#{field_name}/gd
  end

  defp pp_val(str) do
    ~s/#{str}/yd
  end

  defp pp_fields(fields) do
    fields |> Enum.sort |> Enum.map(fn({key, val}) ->
      [key |> to_string |> pp_field_name , ": ", val |> inspect(limit: @field_inspect_limit) |> pp_val]
    end)
  end

  defp pp_command_name(pdu) do
    name = pdu |> Pdu.command_name |> to_string
    ~s/#{name}/DCd
  end

end

