defmodule SMPPEX.ESME.SMPPHandler do

  alias SMPPEX.ESME.SMPPHandler

  defstruct [
    :esme
  ]

  @type t :: %SMPPHandler{}

  @spec new(pid) :: t

  def new(esme), do: %__MODULE__{esme: esme}

end

defimpl SMPPEX.SMPPHandler, for: SMPPEX.ESME.SMPPHandler do

  alias SMPPEX.ESME, as: ESME

  require Logger

  def after_init(_session) do
  end

  def handle_parse_error(session, error) do
    Logger.info("esme #{inspect session.esme}, parse error: #{inspect error}, stopping")
  end

  def handle_pdu(session, {:unparsed_pdu, raw_pdu, error}) do
    Logger.info("esme #{inspect session.esme}, unknown pdu: #{inspect raw_pdu}(#{inspect error}), stopping")
    :stop
  end

  def handle_pdu(session, {:pdu, pdu}) do
    :ok = ESME.handle_pdu(session.esme, pdu)
  end

  def handle_socket_closed(session) do
    Logger.info("esme #{inspect session.esme}, socket closed, stopping")
  end

  def handle_socket_error(session, reason) do
    Logger.info("esme #{inspect session.esme}, socket error #{inspect reason}, stopping")
  end

  def handle_stop(session) do
    :ok = ESME.handle_stop(session.esme)
  end

  def handle_send_pdu_result(session, pdu, send_pdu_result) do
    :ok = ESME.handle_send_pdu_result(session.esme, pdu, send_pdu_result)
    session
  end

end
