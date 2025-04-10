defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation

  # Calculate is performed by Elixir runtime
  # def calculate(tracks, _opts, _context) do
  #   tracks
  #   |> Enum.map(fn %Tunez.Music.Track{duration_seconds: duration} ->
  #     seconds =
  #       duration
  #       |> rem(60)
  #       |> Integer.to_string()
  #       |> String.pad_leading(2, "0")
  #
  #     minutes = div(duration, 60)
  #
  #     "#{minutes}:#{seconds}"
  #   end)
  # end

  # Calculation is performed by Postgres
  def expression(_opts, _context) do
    expr(
      fragment("? / 60 || to_char(? * interval '1s', ':SS')", duration_seconds, duration_seconds)
    )
  end
end
