defmodule TunezWeb.Artists.IndexLive do
  use TunezWeb, :live_view

  require Logger

  @sort_options [
    {"recently updated", "-updated_at"},
    {"recently added", "-inserted_at"},
    {"name", "name"},
    {"number of albums", "-album_count"},
    {"latest album release", "--latest_album_year_released"}
  ]

  @valid_sort_keys Enum.map(@sort_options, &elem(&1, 1))
  @default_sort_key List.first(@valid_sort_keys)

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Artists")

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    query_text = Map.get(params, "q", "")
    sort_by = params |> Map.get("sort_by") |> validate_sort_by()
    artists_page_params = AshPhoenix.LiveView.page_from_params(params, 8)

    artists_page =
      Tunez.Music.search_artists!(query_text,
        page: artists_page_params,
        query: [sort_input: sort_by],
        actor: socket.assigns.current_user
      )

    socket =
      socket
      |> assign(:query_text, query_text)
      |> assign(:artists_page, artists_page)
      |> assign(:sort_by, sort_by)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.header responsive={false}>
      <.h1>Artists</.h1>
      <:action>
        <.search_box query={@query_text} method="get" data-role="artist-search" phx-submit="search" />
      </:action>
      <:action>
        <.sort_changer selected={@sort_by} />
      </:action>
      <:action :if={Tunez.Music.can_create_artist?(@current_user)}>
        <.button_link navigate={~p"/artists/new"} kind="primary">
          New Artist
        </.button_link>
      </:action>
    </.header>

    <div :if={@artists_page == []} class="p-8 text-center">
      <.icon name="hero-face-frown" class="w-32 h-32 bg-gray-300" />
      <br /> No artist data to display!
    </div>

    <ul class="gap-6 lg:gap-12 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4">
      <li :for={artist <- @artists_page.results}>
        <.artist_card artist={artist} />
      </li>
    </ul>

    <.pagination_links artists_page={@artists_page} query_text={@query_text} sort_by={@sort_by} />
    """
  end

  def handle_event("change-sort", %{"sort_by" => sort_by}, socket) do
    params = remove_empty(%{q: socket.assigns.query_text, sort_by: sort_by})
    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  def handle_event("search", %{"query" => query}, socket) do
    params = remove_empty(%{q: query, sort_by: socket.assigns.sort_by})
    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  # -- Private

  defp artist_card(assigns) do
    ~H"""
    <div id={"artist-#{@artist.id}"} data-role="artist-card" class="relative mb-2">
      <.link navigate={~p"/artists/#{@artist.id}"}>
        <.cover_image image={@artist.cover_image_url} />
      </.link>
    </div>
    <p>
      <.link
        navigate={~p"/artists/#{@artist.id}"}
        class="text-lg font-semibold"
        data-role="artist-name"
      >
        {@artist.name}
      </.link>
    </p>
    <.artist_card_album_info artist={@artist} />
    """
  end

  defp artist_card_album_info(%{artist: %{album_count: 0}} = assigns), do: ~H""

  defp artist_card_album_info(assigns) do
    ~H"""
    <span class="mt-2 text-sm leading-6 text-zinc-500">
      {@artist.album_count} {ngettext("album", "albums", @artist.album_count)},
      latest release {@artist.latest_album_year_released}
    </span>
    """
  end

  defp pagination_links(assigns) do
    ~H"""
    <div
      :if={
        AshPhoenix.LiveView.prev_page?(@artists_page) ||
          AshPhoenix.LiveView.next_page?(@artists_page)
      }
      class="flex justify-center pt-8 space-x-4"
    >
      <.button_link
        data-role="previous-page"
        kind="primary"
        inverse
        patch={~p"/?#{query_string(@artists_page, @query_text, @sort_by, "prev")}"}
        disabled={!AshPhoenix.LiveView.prev_page?(@artists_page)}
      >
        « Previous
      </.button_link>
      <.button_link
        data-role="next-page"
        kind="primary"
        inverse
        patch={~p"/?#{query_string(@artists_page, @query_text, @sort_by, "next")}"}
        disabled={!AshPhoenix.LiveView.next_page?(@artists_page)}
      >
        Next »
      </.button_link>
    </div>
    """
  end

  attr :query, :string, default: ""
  attr :rest, :global, include: ~w(method action phx-submit data-role)
  slot :inner_block, required: false

  defp search_box(assigns) do
    ~H"""
    <form class="relative w-fit inline-block" {@rest}>
      <.icon name="hero-magnifying-glass" class="w-4 h-4 m-2 ml-3 mt-4 absolute bg-gray-400" />
      <label for="search-text" class="hidden">Search</label>
      <.input
        class="!rounded-full p-1 pl-8 !w-32 sm:!w-48"
        name="query"
        id="search-text"
        value={@query}
      />
      {render_slot(@inner_block)}
    </form>
    """
  end

  defp sort_changer(assigns) do
    assigns = assign(assigns, :options, @sort_options)

    ~H"""
    <form data-role="artist-sort" class="hidden sm:inline" phx-change="change-sort">
      <.input
        label="sort by:"
        type="select"
        id="sort_by"
        name="sort_by"
        options={@options}
        value={@selected}
        class="px-2 py-0.5 !w-fit !inline-block pr-8 text-sm"
        container_class="!inline-block"
      />
    </form>
    """
  end

  defp validate_sort_by(key) when key in @valid_sort_keys, do: key
  defp validate_sort_by(_), do: @default_sort_key

  defp remove_empty(params) do
    Enum.filter(params, fn {_key, val} -> val != "" end)
  end

  defp query_string(artists_page, query_text, sort_by, which) do
    list =
      case AshPhoenix.LiveView.page_link_params(artists_page, which) do
        :invalid -> []
        list -> list
      end

    list
    |> Keyword.put(:q, query_text)
    |> Keyword.put(:sort_by, sort_by)
    |> remove_empty()
  end
end
