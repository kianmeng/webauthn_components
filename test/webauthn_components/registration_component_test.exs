defmodule WebauthnComponents.RegistrationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.RegistrationComponent

  @id "registration-component"

  setup do
    {:ok, view, html} = live_isolated_component(RegistrationComponent, %{id: @id})
    element = element(view, "##{@id}")
    live_assign(view, :app, :demo)
    %{view: view, html: html, element: element}
  end

  describe "render/1" do
    test "returns element with id and phx hook", %{html: html} do
      assert html =~ "id=\"#{@id}\""
      assert html =~ "phx-hook=\"RegistrationHook\""
    end
  end

  describe "handle_event/3 - register" do
    test "sends registration challenge to client", %{element: element} do
      clicked_element = render_click(element)
      assert clicked_element =~ "<button"
      assert clicked_element =~ "phx-click=\"register\""

      # TODO 1/10/2023
      # Assert event was pushed to client
      # Not supported by Phoenix.LiveViewTest or LiveIsolatedComponent
    end
  end

  describe "handle_event/3 - registration-attestation" do
    test "fails registration with invalid payload", %{element: element, view: view} do
      challenge = build(:registration_challenge)
      live_assign(view, :challenge, challenge)
      live_assign(view, :user_handle, :crypto.strong_rand_bytes(64))

      attestation_64 = Base.encode64(:crypto.strong_rand_bytes(64), padding: false)
      raw_id_64 = Base.encode64(:crypto.strong_rand_bytes(64), padding: false)
      client_data = []

      payload = %{
        "attestation64" => attestation_64,
        "clientData" => client_data,
        "rawId64" => raw_id_64,
        "type" => "public-key"
      }

      assert render_hook(element, "registration-attestation", payload)
      assert_handle_info(view, {:registration_failure, [message: message]})
      assert message =~ "Invalid client data"
    end
  end

  describe "handle_event/3 - error" do
    test "accepts valid payload", %{element: element, view: view} do
      error = %{
        "message" => "test message",
        "name" => "test name",
        "stack" => %{}
      }

      assert render_hook(element, "error", error)
      assert_handle_info(view, {:error, ^error})
    end
  end

  describe "handle_event/3 - fallback" do
    test "sends invalid event to parent view", %{element: element, view: view} do
      assert render_hook(element, "invalid", %{"invalid_key" => "invalid value"})
      assert_handle_info(view, {:invalid_event, "invalid", %{"invalid_key" => "invalid value"}})
    end
  end
end
