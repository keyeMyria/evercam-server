defmodule EvercamMedia.Snapshot.Error do
  @moduledoc """
  TODO
  """
  require Logger
  alias EvercamMedia.Util
  import EvercamMedia.Snapshot.DBHandler, only: [update_camera_status: 5]

  def parse(error) do
    case error do
      %CaseClauseError{} ->
        :bad_request
      %HTTPotion.HTTPError{} ->
        Map.get(error, :message) |> String.to_atom
      error when is_map(error) ->
        Map.get(error, :reason)
      _ ->
        error
    end
  end

  def handle(reason, camera_exid, timestamp, error) do
    case reason do
      :system_limit ->
        Logger.error "[#{camera_exid}] [snapshot_error] [system_limit] Traceback."
        Util.error_handler(error)
        [500, %{message: "Sorry, we dropped the ball."}]
      :emfile ->
        Logger.error "[#{camera_exid}] [snapshot_error] [emfile] Traceback."
        Util.error_handler(error)
        [500, %{message: "Sorry, we dropped the ball."}]
      :bad_request ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [bad_request]"
        update_camera_status("#{camera_exid}", timestamp, false, "bad_request", 50)
        [504, %{message: "Bad request."}]
      :closed ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [closed]"
        update_camera_status("#{camera_exid}", timestamp, false, "closed", 5)
        [504, %{message: "Connection closed."}]
      :nxdomain ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [nxdomain]"
        update_camera_status("#{camera_exid}", timestamp, false, "nxdomain", 100)
        [504, %{message: "Non-existant domain."}]
      :ehostunreach ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [ehostunreach]"
        update_camera_status("#{camera_exid}", timestamp, false, "ehostunreach", 20)
        [504, %{message: "No route to host."}]
      :enetunreach ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [enetunreach]"
        update_camera_status("#{camera_exid}", timestamp, false, "enetunreach", 10)
        [504, %{message: "Network unreachable."}]
      :req_timedout ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [req_timedout]"
        update_camera_status("#{camera_exid}", timestamp, false, "req_timedout", 5)
        [504, %{message: "Request to the camera timed out."}]
      :timeout ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [timeout]"
        update_camera_status("#{camera_exid}", timestamp, false, "timeout", 2)
        [504, %{message: "Camera response timed out."}]
      :connect_timeout ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [connect_timeout]"
        update_camera_status("#{camera_exid}", timestamp, false, "connect_timeout", 2)
        [504, %{message: "Connection to the camera timed out."}]
      :econnrefused ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [econnrefused]"
        update_camera_status("#{camera_exid}", timestamp, false, "econnrefused", 20)
        [504, %{message: "Connection refused."}]
      :not_found ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [not_found]"
        update_camera_status("#{camera_exid}", timestamp, false, "not_found", 100)
        [504, %{message: "Camera url is not found.", response: error[:response]}]
      :forbidden ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [forbidden]"
        update_camera_status("#{camera_exid}", timestamp, false, "forbidden", 100)
        [504, %{message: "Camera responded with a Forbidden message.", response: error[:response]}]
      :unauthorized ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [unauthorized]"
        update_camera_status("#{camera_exid}", timestamp, false, "unauthorized", 100)
        [504, %{message: "Camera responded with a Unauthorized message.", response: error[:response]}]
      :device_error ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [device_error]"
        update_camera_status("#{camera_exid}", timestamp, false, "device_error", 5)
        [504, %{message: "Camera responded with a Device Error message.", response: error[:response]}]
      :device_busy ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [device_busy]"
        update_camera_status("#{camera_exid}", timestamp, false, "device_busy", 1)
        [502, %{message: "Camera responded with a Device Busy message.", response: error[:response]}]
      :not_a_jpeg ->
        Logger.debug "[#{camera_exid}] [snapshot_error] [not_a_jpeg]"
        update_camera_status("#{camera_exid}", timestamp, false, "device_busy", 1)
        [504, %{message: "Camera didn't respond with an image.", response: error[:response]}]
      _reason ->
        Logger.warn "[#{camera_exid}] [snapshot_error] [unhandled] #{inspect error}"
        update_camera_status("#{camera_exid}", timestamp, false, "unhandled", 1)
        [500, %{message: "Sorry, we dropped the ball."}]
    end
  end
end