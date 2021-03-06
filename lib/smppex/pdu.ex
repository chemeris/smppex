defmodule SMPPEX.Pdu do
  alias SMPPEX.Protocol.TlvFormat
  alias SMPPEX.Protocol.CommandNames
  alias SMPPEX.Pdu

  @type t :: %Pdu{}

  defstruct [
    command_id: 0,
    command_status: 0,
    sequence_number: 0,
    ref: nil,
    mandatory: %{},
    optional: %{},
  ]

  @type header :: {integer, integer, integer} | integer

  @spec new(header, map, map) :: t

  def new(header, m_fields \\ %{}, opt_fields \\ %{}) do
    case header do
      c_id when is_integer(c_id) ->
        %Pdu{
          command_id: c_id,
          ref: make_ref,
          mandatory: m_fields,
          optional: opt_fields
        }
      {c_id, c_status, s_number} ->
        %Pdu{
          command_id: c_id,
          command_status: c_status,
          sequence_number: s_number,
          ref: make_ref,
          mandatory: m_fields,
          optional: opt_fields
        }
    end
  end

  @spec command_name(t) :: atom

  def command_name(pdu) do
    case CommandNames.name_by_id(pdu.command_id) do
      {:ok, name} -> name
      :unknown -> :unknown
    end
  end

  @spec command_id(t) :: integer

  def command_id(pdu) do
    pdu.command_id |> to_int
  end

  @spec command_status(t) :: integer

  def command_status(pdu) do
    pdu.command_status |> to_int
  end

  @spec sequence_number(t) :: integer

  def sequence_number(pdu) do
    pdu.sequence_number |> to_int
  end

  @spec mandatory_field(t, atom) :: any

  def mandatory_field(pdu, name) when is_atom(name) do
    pdu.mandatory[name]
  end

  @spec set_mandatory_field(t, atom, any) :: t

  def set_mandatory_field(pdu, name, value) do
    %Pdu{pdu | mandatory: Map.put(pdu.mandatory, name, value)}
  end

  @spec optional_field(t, integer | atom) :: any

  def optional_field(pdu, id) when is_integer(id) do
    pdu.optional[id]
  end

  def optional_field(pdu, name) when is_atom(name) do
    case Map.has_key?(pdu.optional, name) do
      true -> pdu.optional[name]
      false -> case TlvFormat.id_by_name(name) do
        {:ok, id} -> optional_field(pdu, id)
        :unknown -> nil
      end
    end
  end

  @spec set_optional_field(t, atom, any) :: t

  def set_optional_field(pdu, name, value) do
    %Pdu{pdu | optional: Map.put(pdu.optional, name, value)}
  end

  @spec field(t, integer | atom) :: any

  def field(pdu, id) when is_integer(id) do
    optional_field(pdu, id)
  end
  def field(pdu, name) do
    mandatory_field(pdu, name) || optional_field(pdu, name)
  end

  @spec optional_fields(t) :: map

  def optional_fields(pdu), do: pdu.optional

  @spec mandatory_fields(t) :: map

  def mandatory_fields(pdu), do: pdu.mandatory

  @spec same?(t, t) :: boolean

  def same?(pdu1, pdu2), do: pdu1.ref != nil and pdu2.ref != nil and pdu1.ref == pdu2.ref

  @spec resp?(t) :: boolean

  def resp?(pdu), do: Pdu.command_id(pdu) > 0x80000000

  @spec success_resp?(t) :: boolean

  def success_resp?(pdu) do
    resp?(pdu) and Pdu.command_status(pdu) == 0
  end

  @spec bind?(t) :: boolean

  def bind?(pdu) do
    command_id = Pdu.command_id(pdu)
    case CommandNames.name_by_id(command_id) do
      {:ok, command_name} -> command_name == :bind_receiver or command_name == :bind_transmitter or command_name == :bind_transceiver
      :unknown -> false
    end
  end

  @spec bind_resp?(t) :: boolean

  def bind_resp?(pdu) do
    command_id = Pdu.command_id(pdu)
    case CommandNames.name_by_id(command_id) do
      {:ok, command_name} -> command_name == :bind_receiver_resp or command_name == :bind_transmitter_resp or command_name == :bind_transceiver_resp
      :unknown -> false
    end
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(_), do: 0

end
