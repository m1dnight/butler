defmodule ButlerWeb.ChatLog do
  use Phoenix.Component

  use Gettext, backend: ButlerWeb.Gettext

  attr :id, :string
  attr :user, :string, required: true
  attr :count, :integer, required: true

  def message_count(assigns) do
    ~H"""
    <div class="karma font-mono">
      <div class="karma_user mr-2"><%= @user %></div>
      <div class="karma_value"><%= @count %></div>
    </div>
    """
  end

  attr :id, :string
  attr :user, :string, required: true
  attr :karma, :integer, required: true

  def karma(assigns) do
    ~H"""
    <div class="karma font-mono">
      <div class="karma_user mr-2"><%= @user %></div>
      <div class="karma_value"><%= @karma %></div>
    </div>
    """
  end

  attr :id, :string
  attr :sender, :string, required: true
  attr :timestamp, DateTime, required: true
  attr :content, :string, required: true

  def message(assigns) do
    ~H"""
    <div class="message font-mono">
      <div class="timestamp mr-2 text-sm">
        <%= @timestamp |> DateTime.to_time() |> Time.truncate(:second) |> Time.to_iso8601() %>
      </div>
      <div
        class="name mr-2"
        style={"color: ##{:crypto.hash(:md5, @sender) |> :binary.bin_to_list |> Enum.take(3) |> :binary.list_to_bin |> Base.encode16}"}
      >
        <%= @sender %>
      </div>
      <div class="content">
        <%= @content %>
      </div>
    </div>
    """
  end

  slot :inner_block, doc: "the optional inner block that renders the flash message"
  attr :title, :string, required: false, default: nil
  attr :width, :float, required: false, default: 1.0

  def panel(assigns) do
    class =
      case assigns.width do
        0.5 -> "basis-1/2"
        0.33 -> "basis-1/3"
        1 -> "basis-full"
        _ -> "basis-full"
      end

    ~H"""
    <div class={"panel p-5 m-1 border-2 border-slate-100 rounded " <>  class}>
      <div class="title text-lg"><%= @title %></div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def row(assigns) do
    ~H"""
    <div class="row">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
